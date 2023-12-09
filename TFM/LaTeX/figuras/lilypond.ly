\version "2.18.2"  % Asegúrate de usar la versión correcta de LilyPond

\header {
  title = "Melodía al Estilo de Bach"
  composer = "Composición Ejemplo"
}

\score {
  \new Staff {
    \key c \major
    \time 4/4
    \tempo 4 = 100

    % Compás 1
    c'4 d' e' g' |

    % Compás 2
    f' e' d' c' |

    % Compás 3
    e'4 f' g' a' |

    % Compás 4
    g' f' e' d' |
  }
  \layout { }
  \midi { }
}

