--              Felipe Ferreira Nascimento
-- Circuito dedicado para síntese na geração de funcao seno pelo polinômio para 5 constantes
-- sen(x) = C1X + C2X2 + C3X3 + C4X4 + C5X5
-- Constantes formatadas para os valores de ponto fixo 4.13
-- Variaveis formatadas para os valores de ponto  fixo 2.14

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY dv_converters;
USE dv_converters.converters_signed_to_real_pkg.ALL;

ENTITY MAC_SEN_POLY IS
generic (
    CI    : INTEGER := 4;  -- qtd de bits parte inteira 1º num (constantes sen)
    CF    : INTEGER := 13; -- qtd de bits parte fracionaria 1º num
    XI    : INTEGER := 2;  -- qtd de bits parte inteira 2º num (variaveis)
    XF    : INTEGER := 14  -- qtd de bits parte fracionaria 2º num (variaves sen)
  );   
  PORT ( 
        CLK                 : IN STD_LOGIC;
        A                   : IN SIGNED (CI + CF - 1 DOWNTO 0); -- 1º num aplicado ao sistema 
        B                   : IN SIGNED (XI + XF - 1 DOWNTO 0); -- 2º num aplicado ao sistema 
        CTRL_SEND_DATA      : IN INTEGER RANGE 0 TO 5;          -- Controle no Recebimento das constantes. Sistema aceita 5 Constantes. + 1 CTRL
        VALUE_OF_X_RECEIVED : IN BIT;                           -- Flag para indicar o recebimento do valor da entrada da variavel X
        REQUEST_VALUE_OF_X  : OUT BIT;                          -- Flag para requisitar o valor de entrada da variavel X
        OUT_BIN             : OUT SIGNED (24 - 1 DOWNTO 0);     -- Saída do sistema em formato bits ponto fixo (síntese)
        OUT_REAL            : OUT REAL                          -- Saída do sistema em formato real (simulacao)
  );
END MAC_SEN_POLY;

ARCHITECTURE exemplo OF MAC_SEN_POLY IS

BEGIN
    PROCESS(CLK)
    CONSTANT SIZE_TRUNC : INTEGER := 24;      -- Valores são ajustados e truncados para 24 bits. -- pode ser alterado 
    CONSTANT SIZE_TRUNC_FRAC : INTEGER := 18; -- Valores são ajustados e truncados para 18 bits. -- pode ser alterado 
    CONSTANT SIZE_TRUNC_INT : INTEGER := SIZE_TRUNC - SIZE_TRUNC_FRAC;
    CONSTANT SIZE_X1    : INTEGER := XI + XF; 
    CONSTANT SIZE_X2    : INTEGER := SIZE_X1 + XI + XF;
    CONSTANT SIZE_X3    : INTEGER := SIZE_X2 + XI + XF;
    CONSTANT SIZE_X4    : INTEGER := SIZE_X3 + XI + XF;
    CONSTANT SIZE_X5    : INTEGER := SIZE_X4 + XI + XF;
    CONSTANT SIZE_CX1   : INTEGER := SIZE_X1 + CI + CF; -- Valores são ajustados e truncados para 33 bits
    CONSTANT SIZE_CXS   : INTEGER := (CI + SIZE_TRUNC_INT) + (CF + SIZE_TRUNC_FRAC);
    -- Apos as multiplicações valores com o formatos abaixo
    VARIABLE X  : SIGNED (SIZE_X1 - 1 DOWNTO 0); -- X  = 2.14
    VARIABLE X2 : SIGNED (SIZE_X2 - 1 DOWNTO 0); -- X2 = 4.28
    VARIABLE X3 : SIGNED (SIZE_X3 - 1 DOWNTO 0); -- X3 = 6.42
    VARIABLE X4 : SIGNED (SIZE_X4 - 1 DOWNTO 0); -- X4 - 8.56
    VARIABLE X5 : SIGNED (SIZE_X5 - 1 DOWNTO 0); -- X4 - 10.70
    -- Apos as multiplicações valores são truncados e mantidos com os formatos abaixo (4.13 + 2.14)
    VARIABLE C1X : SIGNED(SIZE_CX1 - 1 DOWNTO 0); -- X*C1  - (4.13 + 2.14)  - 6.27
        -- (4.13 + 6.18) = 10.31
    VARIABLE C2X : SIGNED(SIZE_CXS - 1 DOWNTO 0); -- X2*C2 - 10.31
    VARIABLE C3X : SIGNED(SIZE_CXS - 1 DOWNTO 0); -- X3*C4 - 10.31
    VARIABLE C4X : SIGNED(SIZE_CXS - 1 DOWNTO 0); -- X4*C5 - 10.31
    VARIABLE C5X : SIGNED(SIZE_CXS - 1 DOWNTO 0); -- X5*C6 - 10.31
     
    VARIABLE X2_truncated, X3_truncated, X4_truncated, X5_truncated                    : SIGNED(SIZE_TRUNC - 1 DOWNTO 0); -- 6.18
    VARIABLE C1X_truncated, C2X_truncated, C3X_truncated, C4X_truncated, C5X_truncated : SIGNED(SIZE_TRUNC - 1 DOWNTO 0); -- 6.18

    VARIABLE X2p_int, X3p_int, X4p_int, X5p_int                                        : SIGNED(SIZE_TRUNC_INT - 1 DOWNTO 0);  -- 6.
    VARIABLE C1Xp_int,  C2Xp_int,  C3Xp_int,  C4Xp_int,  C5Xp_int                      : SIGNED(SIZE_TRUNC_INT - 1 DOWNTO 0);  -- 6.

    VARIABLE X2p_frac, X3p_frac, X4p_frac, X5p_frac                                    : SIGNED(SIZE_TRUNC_FRAC - 1 DOWNTO 0);  -- .18

    VARIABLE C1Xp_frac, C2Xp_frac, C3Xp_frac, C4Xp_frac, C5Xp_frac : SIGNED(SIZE_TRUNC_FRAC - 1 DOWNTO 0); -- .18 

    VARIABLE sum : SIGNED(SIZE_TRUNC - 1 DOWNTO 0); -- 6.18
    VARIABLE y : SIGNED(SIZE_TRUNC - 1 DOWNTO 0); -- resultado final no formato 6.18

    VARIABLE integer_result : INTEGER;
    VARIABLE r_c1x, r_c2x, r_c3x, r_c4x, r_c5x, r_Y : REAL;
    VARIABLE r_x,   r_x2,  r_x3,  r_x4, r_x5        : REAL;

    type state_type is (s_wait, s_init, s0, s1, s2, s3, s4, s5, s6, result);
    type t_state_type is (t1);
    VARIABLE state   : state_type := s_init;

    VARIABLE C1, C2, C3, C4, C5 : SIGNED (CI + CF - 1 DOWNTO 0); -- constantes 4.13
    BEGIN
        IF (CLK'event AND CLK = '1') THEN
            CASE state is
                WHEN s_init =>
                    CASE CTRL_SEND_DATA IS
                        WHEN 0 => C1 := A;
                        WHEN 1 => C2 := A;
                        WHEN 2 => C3 := A;
                        WHEN 3 => C4 := A;
                        WHEN 4 => C5 := A;
                        WHEN 5 => state := s_wait;
                    END CASE;
                WHEN s_wait =>
                        REQUEST_VALUE_OF_X <= '1';
                        IF VALUE_OF_X_RECEIVED = '1' THEN
                            X := B;
                            state := s0;
                            REQUEST_VALUE_OF_X <= '0';
                        END IF;
                WHEN s0 =>
                    -- Realiza o truncamento p/ o formato 6.18
                    X2 := X * X; -- X2 = X * X = (2.14 + 2.14) = ( 4.28 ) (32b) 
                    integer_result := TO_INTEGER(X2(SIZE_X2 - 1 DOWNTO SIZE_X2 - (2*XI)));
                    X2p_int := TO_SIGNED(integer_result, X2p_int'LENGTH); -- 6.
                    X2p_frac := X2((SIZE_X2 - (2*XI)) - 1  DOWNTO (SIZE_X2 - (2*XI)) - SIZE_TRUNC_FRAC); -- .18
                    X2_truncated(SIZE_TRUNC - 1 DOWNTO SIZE_TRUNC - SIZE_TRUNC_INT) := X2p_int; 
                    X2_truncated(SIZE_TRUNC_FRAC - 1 DOWNTO 0)  := X2p_frac; -- trunca p/ 6.18

                    X3 := X2 * X; -- X3 = X2*X = (4.28) + 2.14 = ( 6.42 ) (48b)
                    integer_result := TO_INTEGER(X3(SIZE_X3 - 1 DOWNTO SIZE_X3 - (2*XI + XI)));
                    X3p_int := TO_SIGNED(integer_result, X3p_int'LENGTH); -- 6.
                    X3p_frac := X3((SIZE_X3 - (2*XI + XI)) - 1 DOWNTO (SIZE_X3 - (2*XI + XI)) - SIZE_TRUNC_FRAC); -- .18
                    X3_truncated(SIZE_TRUNC - 1 DOWNTO SIZE_TRUNC - SIZE_TRUNC_INT) := X3p_int;
                    X3_truncated(SIZE_TRUNC_FRAC - 1 DOWNTO 0)  := X3p_frac; -- trunca p/ 6.18

                    X4 := X3 * X; -- X4 = X3*X = (6.42) + 2.14 = ( 8.56 ) (64b)
                    integer_result := TO_INTEGER(X4(SIZE_X4 - 1 DOWNTO SIZE_X4 - ((2*XI + XI) + XI))); 
                    X4p_int := TO_SIGNED(integer_result, X4p_int'LENGTH); -- 6.
                    X4p_frac := X4((SIZE_X4 - ((2*XI + XI) + XI)) - 1 DOWNTO ((SIZE_X4 - ((2*XI + XI) + XI)) - SIZE_TRUNC_FRAC)); -- .18
                    X4_truncated(SIZE_TRUNC - 1 DOWNTO SIZE_TRUNC - SIZE_TRUNC_INT) := X4p_int;
                    X4_truncated(SIZE_TRUNC_FRAC - 1 DOWNTO 0)  := X4p_frac; -- trunca p/ 6.18

                    X5 := X4 * X; -- X5 = X4*X = (8.56) + (2.14) = ( 10.70 ) (80b)
                    integer_result := TO_INTEGER(X5(SIZE_X5 - 1 DOWNTO SIZE_X5 - (((2*XI + XI) + XI) + XI))); 
                    X5p_int := TO_SIGNED(integer_result, X5p_int'LENGTH); -- 6.
                    X5p_frac := X5((SIZE_X5 - (((2*XI + XI) + XI) + XI)) - 1 DOWNTO ((SIZE_X5 - (((2*XI + XI) + XI) + XI)) - SIZE_TRUNC_FRAC)); -- .18
                    X5_truncated(SIZE_TRUNC - 1 DOWNTO SIZE_TRUNC - SIZE_TRUNC_INT) := X5p_int;
                    X5_truncated(SIZE_TRUNC_FRAC - 1 DOWNTO 0)  := X5p_frac; -- trunca p/ 6.18
                    state := s1;
                WHEN s1 =>
                    C1X := X * C1;            --  2.14  + 4.13 = 6.27  (33b)
                    C2X := X2_truncated * C2; -- (6.18) + 4.13 = 10.31 (41b)
                    C3X := X3_truncated * C3; -- (6.18) + 4.13 = 10.31 (41b)
                    C4X := X4_truncated * C4; -- (6.18) + 4.13 = 10.31 (41b)
                    C5X := X5_truncated * C5; -- (6.18) + 4.13 = 10.31 (41b)
                    state := s2;
                WHEN s2 =>
                    -- truncando resultados para o formato 6.18
                    integer_result := TO_INTEGER(C1X(SIZE_CX1 - 1 DOWNTO SIZE_CX1 - (CI + XI))); -- (6).27
                    C1Xp_int := TO_SIGNED(integer_result, C1Xp_int'LENGTH);
                    C1Xp_frac := C1X((SIZE_CX1 - (CI + XI)) - 1 DOWNTO (SIZE_CX1 - (CI + XI)) - SIZE_TRUNC_FRAC);
                    C1X_truncated(SIZE_TRUNC - 1 DOWNTO SIZE_TRUNC - SIZE_TRUNC_INT) := C1Xp_int;
                    C1X_truncated(SIZE_TRUNC_FRAC - 1 DOWNTO 0)  := C1Xp_frac; -- trunca p/ 6.18

                    integer_result := TO_INTEGER(C2X(SIZE_CXS - 1 DOWNTO SIZE_CXS - (SIZE_TRUNC_INT + CI))); -- (8).31 
                    C2Xp_int := TO_SIGNED(integer_result, C2Xp_int'LENGTH); -- 6.
                    C2Xp_frac := C2X((SIZE_CXS - (SIZE_TRUNC_INT + CI)) - 1 DOWNTO (SIZE_CXS - (SIZE_TRUNC_INT + CI)) - SIZE_TRUNC_FRAC); -- 6.18
                    C2X_truncated(SIZE_TRUNC - 1 DOWNTO SIZE_TRUNC - SIZE_TRUNC_INT) := C2Xp_int; 
                    C2X_truncated(SIZE_TRUNC_FRAC - 1 DOWNTO 0)  := C2Xp_frac; -- trunca p/ 6.18

                    integer_result := TO_INTEGER(C3X(SIZE_CXS - 1 DOWNTO SIZE_CXS - (SIZE_TRUNC_INT + CI))); 
                    C3Xp_int := TO_SIGNED(integer_result, C3Xp_int'LENGTH); -- 6.
                    C3Xp_frac := C3X((SIZE_CXS - (SIZE_TRUNC_INT + CI)) - 1 DOWNTO (SIZE_CXS - (SIZE_TRUNC_INT + CI)) - SIZE_TRUNC_FRAC); 
                    C3X_truncated(SIZE_TRUNC - 1 DOWNTO SIZE_TRUNC - SIZE_TRUNC_INT) := C3Xp_int; 
                    C3X_truncated(SIZE_TRUNC_FRAC - 1 DOWNTO 0)  := C3Xp_frac; -- trunca p/ 6.18

                    integer_result := TO_INTEGER(C4X(SIZE_CXS - 1 DOWNTO SIZE_CXS - (SIZE_TRUNC_INT + CI))); 
                    C4Xp_int := TO_SIGNED(integer_result, C4Xp_int'LENGTH); -- 6.
                    C4Xp_frac := C4X((SIZE_CXS - (SIZE_TRUNC_INT + CI)) - 1 DOWNTO (SIZE_CXS - (SIZE_TRUNC_INT + CI)) - SIZE_TRUNC_FRAC); 
                    C4X_truncated(SIZE_TRUNC - 1 DOWNTO SIZE_TRUNC - SIZE_TRUNC_INT) := C4Xp_int; 
                    C4X_truncated(SIZE_TRUNC_FRAC - 1 DOWNTO 0)  := C4Xp_frac; -- trunca p/ 6.18

                    integer_result := TO_INTEGER(C5X(SIZE_CXS - 1 DOWNTO SIZE_CXS - (SIZE_TRUNC_INT + CI))); 
                    C5Xp_int := TO_SIGNED(integer_result, C5Xp_int'LENGTH); -- 6.
                    C5Xp_frac := C5X((SIZE_CXS - (SIZE_TRUNC_INT + CI)) - 1 DOWNTO (SIZE_CXS - (SIZE_TRUNC_INT + CI)) - SIZE_TRUNC_FRAC); 
                    C5X_truncated(SIZE_TRUNC - 1 DOWNTO SIZE_TRUNC - SIZE_TRUNC_INT) := C5Xp_int; 
                    C5X_truncated(SIZE_TRUNC_FRAC - 1 DOWNTO 0)  := C5Xp_frac; -- trunca p/ 6.18
                    state := s3;
                WHEN s3 =>
                    sum := C2X_truncated + C1X_truncated; -- 6.18
                    state := s4;
                WHEN s4 =>
                    sum := sum + C3X_truncated; -- 6.18
                    state := s5;
                WHEN s5 =>
                    sum := sum + C4X_truncated; -- 6.18
                    state := s6;
                WHEN s6 =>
                    sum := sum + C5X_truncated; -- 6.18
                    y := sum; -- resultado final truncado para 6.18
                    state := result;
                WHEN result =>
                    state := s_wait;
            END CASE;
            
            convert_signed_to_real(X,  XI, XF, r_x);
            convert_signed_to_real(X2, 2*XI, 2*XF, r_x2);
            convert_signed_to_real(X3, 2*XI + XI, 2*XF + XF, r_x3);
            convert_signed_to_real(X4, (2*XI + XI) + XI, (2*XF + XF) + XF, r_x4);
            convert_signed_to_real(X5, ((2*XI + XI) + XI) + XI, ((2*XF + XF) + XF) + XF, r_x5);
            -- Apresenta valores convertidos das multiplicacoes no formato truncado 6.18
            convert_signed_to_real(C1X, XI + CI, XF + CF, r_c1x);
            convert_signed_to_real(C2X, SIZE_TRUNC_INT + CI, SIZE_TRUNC_FRAC + CF, r_c2x);
            convert_signed_to_real(C3X, SIZE_TRUNC_INT + CI, SIZE_TRUNC_FRAC + CF, r_c3x);
            convert_signed_to_real(C4X, SIZE_TRUNC_INT + CI, SIZE_TRUNC_FRAC + CF, r_c4x);
            convert_signed_to_real(C5X, SIZE_TRUNC_INT + CI, SIZE_TRUNC_FRAC + CF, r_c5x);

            convert_signed_to_real(y, SIZE_TRUNC_INT, SIZE_TRUNC_FRAC, r_Y);
            OUT_REAL <= r_Y;
            OUT_BIN <= y;
        END IF;
    END PROCESS;

END exemplo;