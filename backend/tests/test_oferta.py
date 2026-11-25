"""Contrato de importação e integração com a oferta SIGAA versionada de 2026/2.

Usa o Janus e o motor Prolog reais. Não depende de servidor HTTP nem de
consultas ao SIGAA; mudanças intencionais no semestre exigem revisar os casos.
"""

import unittest

from pydantic import ValidationError

from server import Requisicao, gerar_grades, grupos_prerequisitos


class GruposPrerequisitosTest(unittest.TestCase):
    def test_conjuncao_separa_requisitos_obrigatorios(self):
        self.assertEqual(
            grupos_prerequisitos("FGA0158 e FGA0003"),
            [["FGA0158"], ["FGA0003"]],
        )

    def test_disjuncao_preserva_alternativas_no_mesmo_grupo(self):
        for texto, esperado in [
            ("FGA0085 ou FGA0159", [["FGA0085", "FGA0159"]]),
            ("(FGA0182 ou FGA0096) ou FGA0142", [["FGA0182", "FGA0096", "FGA0142"]]),
        ]:
            with self.subTest(texto=texto):
                self.assertEqual(grupos_prerequisitos(texto), esperado)

    def test_conjuncao_com_alternativas_preserva_os_grupos(self):
        self.assertEqual(
            grupos_prerequisitos("(ENE0277 ou FGA0071) e FGA0073"),
            [["ENE0277", "FGA0071"], ["FGA0073"]],
        )

    def test_formato_desconhecido_nao_elimina_restricoes_silenciosamente(self):
        with self.assertRaises(ValueError):
            grupos_prerequisitos("FGA0158 e requisito desconhecido")


class OfertaSigaaTest(unittest.TestCase):
    def gerar(self, cursadas, bloqueados):
        return gerar_grades(
            Requisicao(
                cursadas=cursadas,
                desejadas=["FGA0210"],
                bloqueados=bloqueados,
                peso_janelas=3,
                peso_dias=2,
            )
        )["grades"]

    def turmas(self, grades):
        ids = []
        for grade in grades:
            self.assertEqual(len(grade["turmas"]), 1)
            turma = grade["turmas"][0]
            self.assertEqual(turma["codigo"], "FGA0210")
            self.assertTrue(turma["horarios"])
            ids.append(turma["turma"])
        return ids

    def test_paradigmas_tem_tres_opcoes_com_os_requisitos_cumpridos(self):
        grades = self.gerar(["FGA0158", "FGA0003"], [])
        self.assertCountEqual(self.turmas(grades), ["01", "02", "03"])
        self.assertEqual([g["rank"] for g in grades], [1, 2, 3])
        self.assertEqual([g["score"] for g in grades], sorted(g["score"] for g in grades))

    def test_bloqueio_de_terca_a_tarde_exclui_a_turma_01(self):
        grades = self.gerar(["FGA0158", "FGA0003"], ["3T4"])
        self.assertCountEqual(self.turmas(grades), ["02", "03"])

    def test_falta_de_qualquer_requisito_impede_paradigmas(self):
        for cursadas in [[], ["FGA0158"], ["FGA0003"]]:
            with self.subTest(cursadas=cursadas):
                self.assertEqual(self.gerar(cursadas, []), [])

    def test_pontuacao_usa_pesos_enviados_na_requisicao(self):
        grades = self.gerar(["FGA0158", "FGA0003"], [])
        for grade in grades:
            self.assertEqual(grade["score"], 3 * grade["janelas"] + 2 * grade["dias_campus"])

    def test_pesos_negativos_sao_rejeitados(self):
        with self.assertRaises(ValidationError):
            Requisicao(desejadas=["FGA0210"], peso_janelas=-1)


if __name__ == "__main__":
    unittest.main()
