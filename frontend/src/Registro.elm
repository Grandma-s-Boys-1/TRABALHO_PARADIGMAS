module Registro exposing (modulos)

import Ajuda exposing (Modulo)
import Fases.Alcance
import Fases.Candidatos
import Fases.Canto
import Fases.Dica
import Fases.Fila
import Fases.Largadas
import Fases.Troca


modulos : List Modulo
modulos =
    [ Fases.Candidatos.modulo
    , Fases.Dica.modulo
    , Fases.Canto.modulo
    , Fases.Troca.modulo
    , Fases.Largadas.modulo
    , Fases.Fila.modulo
    , Fases.Alcance.modulo
    ]
