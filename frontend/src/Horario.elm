module Horario exposing
    ( Dia(..), dias, nomeDia, abreviacaoDia
    , Turno(..), turnos, nomeTurno
    , Periodo, periodos, periodosDoTurno, turno, ordem, codigoPeriodo, inicio, fim
    , Slot, codigoSlot
    , Horario, deTexto, paraTexto, slots, descricao
    )

{-| Horários da UnB no formato do SIGAA, como `24M34`: segunda e quarta, manhã,
terceiro e quarto períodos.

`Periodo` e `Horario` são opacos: só existem valores que o motor Prolog também
aceita (dias 2 a 7, M1 a M5, T1 a T6 e N1 a N4).

@docs Dia, dias, nomeDia, abreviacaoDia
@docs Turno, turnos, nomeTurno
@docs Periodo, periodos, periodosDoTurno, turno, ordem, codigoPeriodo, inicio, fim
@docs Slot, codigoSlot
@docs Horario, deTexto, paraTexto, slots, descricao

-}

-- DIAS


type Dia
    = Segunda
    | Terca
    | Quarta
    | Quinta
    | Sexta
    | Sabado


dias : List Dia
dias =
    [ Segunda, Terca, Quarta, Quinta, Sexta, Sabado ]


nomeDia : Dia -> String
nomeDia dia =
    case dia of
        Segunda ->
            "Segunda"

        Terca ->
            "Terça"

        Quarta ->
            "Quarta"

        Quinta ->
            "Quinta"

        Sexta ->
            "Sexta"

        Sabado ->
            "Sábado"


abreviacaoDia : Dia -> String
abreviacaoDia dia =
    String.left 3 (nomeDia dia)


numeroDia : Dia -> Int
numeroDia dia =
    case dia of
        Segunda ->
            2

        Terca ->
            3

        Quarta ->
            4

        Quinta ->
            5

        Sexta ->
            6

        Sabado ->
            7



-- TURNOS


type Turno
    = Manha
    | Tarde
    | Noite


turnos : List Turno
turnos =
    [ Manha, Tarde, Noite ]


nomeTurno : Turno -> String
nomeTurno valor =
    case valor of
        Manha ->
            "Manhã"

        Tarde ->
            "Tarde"

        Noite ->
            "Noite"


letraTurno : Turno -> String
letraTurno valor =
    case valor of
        Manha ->
            "M"

        Tarde ->
            "T"

        Noite ->
            "N"



-- PERÍODOS


{-| Um dos quinze períodos de aula do dia, de M1 a N4.
-}
type Periodo
    = Periodo
        { turno : Turno
        , indice : Int
        , ordem : Int
        , inicio : String
        , fim : String
        }


{-| Todos os períodos, em ordem cronológica.
-}
periodos : List Periodo
periodos =
    [ ( Manha, 1, ( "08:00", "08:55" ) )
    , ( Manha, 2, ( "08:55", "09:50" ) )
    , ( Manha, 3, ( "10:00", "10:55" ) )
    , ( Manha, 4, ( "10:55", "11:50" ) )
    , ( Manha, 5, ( "12:00", "12:55" ) )
    , ( Tarde, 1, ( "12:55", "13:50" ) )
    , ( Tarde, 2, ( "14:00", "14:55" ) )
    , ( Tarde, 3, ( "14:55", "15:50" ) )
    , ( Tarde, 4, ( "16:00", "16:55" ) )
    , ( Tarde, 5, ( "16:55", "17:50" ) )
    , ( Tarde, 6, ( "18:00", "18:55" ) )
    , ( Noite, 1, ( "19:00", "19:50" ) )
    , ( Noite, 2, ( "19:50", "20:40" ) )
    , ( Noite, 3, ( "20:50", "21:40" ) )
    , ( Noite, 4, ( "21:40", "22:30" ) )
    ]
        |> List.indexedMap
            (\posicao ( turnoDoPeriodo, indice, ( comeco, termino ) ) ->
                Periodo
                    { turno = turnoDoPeriodo
                    , indice = indice
                    , ordem = posicao + 1
                    , inicio = comeco
                    , fim = termino
                    }
            )


periodosDoTurno : Turno -> List Periodo
periodosDoTurno valor =
    List.filter (\periodo -> turno periodo == valor) periodos


turno : Periodo -> Turno
turno (Periodo periodo) =
    periodo.turno


{-| Posição do período no dia, de 1 (M1) a 15 (N4). É a mesma escala usada em
`prolog/regras.pl`, então M5 e T1 são consecutivos.
-}
ordem : Periodo -> Int
ordem (Periodo periodo) =
    periodo.ordem


codigoPeriodo : Periodo -> String
codigoPeriodo (Periodo periodo) =
    letraTurno periodo.turno ++ String.fromInt periodo.indice


inicio : Periodo -> String
inicio (Periodo periodo) =
    periodo.inicio


fim : Periodo -> String
fim (Periodo periodo) =
    periodo.fim



-- SLOTS


{-| Um período de um dia: a menor unidade da grade.
-}
type alias Slot =
    { dia : Dia
    , periodo : Periodo
    }


{-| Código SIGAA de um único slot, como `2M3`.
-}
codigoSlot : Slot -> String
codigoSlot slot =
    String.fromInt (numeroDia slot.dia) ++ codigoPeriodo slot.periodo



-- HORÁRIOS


{-| Horário SIGAA válido. Mantém o texto original para exibição.
-}
type Horario
    = Horario String (List Slot)


{-| Interpreta um código SIGAA. Como no motor Prolog, dígitos repetidos ou fora
de ordem são aceitos, e qualquer dia ou período inexistente invalida o código.
-}
deTexto : String -> Maybe Horario
deTexto texto =
    let
        ( digitosDias, resto ) =
            separarDigitos (String.toList texto)
    in
    case resto of
        letra :: digitosPeriodos ->
            Maybe.map2
                (\diasLidos periodosLidos ->
                    Horario texto (combinar diasLidos periodosLidos)
                )
                (lerTodos lerDia digitosDias)
                (turnoDaLetra letra
                    |> Maybe.andThen
                        (\valor -> lerTodos (lerPeriodo valor) digitosPeriodos)
                )

        [] ->
            Nothing


paraTexto : Horario -> String
paraTexto (Horario texto _) =
    texto


{-| Slots do horário, sem repetição e em ordem cronológica.
-}
slots : Horario -> List Slot
slots (Horario _ lista) =
    lista


{-| Horário por extenso: `24M34` vira `Seg e Qua, 10:00–11:50`.
Períodos não consecutivos viram intervalos separados.
-}
descricao : Horario -> String
descricao (Horario _ lista) =
    let
        diasUsados =
            List.filter (\dia -> List.any (\slot -> slot.dia == dia) lista) dias

        periodosUsados =
            List.filter (\periodo -> List.any (\slot -> slot.periodo == periodo) lista) periodos

        intervalos =
            periodosUsados
                |> List.foldr juntarConsecutivos []
                |> List.map (\( primeiro, ultimo ) -> inicio primeiro ++ "–" ++ fim ultimo)
    in
    enumerar (List.map abreviacaoDia diasUsados) ++ ", " ++ enumerar intervalos



-- AUXILIARES


separarDigitos : List Char -> ( List Char, List Char )
separarDigitos caracteres =
    case caracteres of
        caractere :: resto ->
            if Char.isDigit caractere then
                Tuple.mapFirst ((::) caractere) (separarDigitos resto)

            else
                ( [], caracteres )

        [] ->
            ( [], [] )


{-| Só tem sucesso se a lista não for vazia e todos os itens forem válidos.
-}
lerTodos : (Char -> Maybe a) -> List Char -> Maybe (List a)
lerTodos ler caracteres =
    if List.isEmpty caracteres then
        Nothing

    else
        List.foldr (\caractere -> Maybe.map2 (::) (ler caractere)) (Just []) caracteres


lerDia : Char -> Maybe Dia
lerDia caractere =
    primeiroQue (\dia -> String.fromInt (numeroDia dia) == String.fromChar caractere) dias


turnoDaLetra : Char -> Maybe Turno
turnoDaLetra letra =
    primeiroQue (\valor -> letraTurno valor == String.fromChar letra) turnos


lerPeriodo : Turno -> Char -> Maybe Periodo
lerPeriodo valor caractere =
    primeiroQue
        (\periodo -> codigoPeriodo periodo == letraTurno valor ++ String.fromChar caractere)
        periodos


combinar : List Dia -> List Periodo -> List Slot
combinar diasLidos periodosLidos =
    dias
        |> List.filter (\dia -> List.member dia diasLidos)
        |> List.concatMap
            (\dia ->
                periodos
                    |> List.filter (\periodo -> List.member periodo periodosLidos)
                    |> List.map (Slot dia)
            )


juntarConsecutivos : Periodo -> List ( Periodo, Periodo ) -> List ( Periodo, Periodo )
juntarConsecutivos periodo intervalos =
    case intervalos of
        ( primeiro, ultimo ) :: resto ->
            if ordem periodo + 1 == ordem primeiro then
                ( periodo, ultimo ) :: resto

            else
                ( periodo, periodo ) :: intervalos

        [] ->
            [ ( periodo, periodo ) ]


enumerar : List String -> String
enumerar itens =
    case List.reverse itens of
        ultimo :: penultimo :: anteriores ->
            String.join ", " (List.reverse (penultimo :: anteriores)) ++ " e " ++ ultimo

        _ ->
            String.concat itens


primeiroQue : (a -> Bool) -> List a -> Maybe a
primeiroQue condicao lista =
    List.head (List.filter condicao lista)
