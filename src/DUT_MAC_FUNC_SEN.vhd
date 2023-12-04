LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY dv_converters;
USE dv_converters.converters_signed_to_real_pkg.ALL;

ENTITY DUT_MAC_FUNC_SEN IS
generic (
    CI     : INTEGER := 4;  -- qtd de bits parte inteira para o 1º num
    CF     : INTEGER := 13; -- qtd de bits parte fracionaria  o 1º num
    XI    : INTEGER  := 2;  -- qtd de bits parte inteira para o 2º num 
    XF    : INTEGER  := 14  -- qtd de bits parte fracionaria  o 2º num
  );  
  PORT ( 
        CLK_DUT                 : BUFFER STD_LOGIC;
        A_DUT                   : BUFFER SIGNED (CI + CF - 1 DOWNTO 0); -- 1º num aplicado ao sistema representado em binario ponto fixo
        B_DUT                   : BUFFER SIGNED (XI + XF - 1 DOWNTO 0); -- 2º num aplicado ao sistema representado em binario ponto fixo
        CTRL_SEND_DATA_DUT      : BUFFER INTEGER RANGE 0 TO 5; 
        REQUEST_VALUE_OF_X_DUT  : BUFFER BIT;
        VALUE_OF_X_SENT_DUT     : BUFFER BIT;
        OUT_BIN_DUT             : BUFFER SIGNED (24 - 1 DOWNTO 0); 
        OUT_REAL_DUT            : BUFFER REAL
  );
END DUT_MAC_FUNC_SEN;

ARCHITECTURE COMPORTAMENTAL OF DUT_MAC_FUNC_SEN IS
COMPONENT MAC_SEN_POLY is
    GENERIC (CI : INTEGER; CF : INTEGER; XI : INTEGER; XF: INTEGER);  
    PORT ( 
        CLK                : IN STD_LOGIC;
        A                  : IN SIGNED (CI + CF - 1 DOWNTO 0); -- 1º num aplicado ao sistema representado em binario 
        B                  : IN SIGNED (XI + XF - 1 DOWNTO 0); -- 2º num aplicado ao sistema representado em binario 
        CTRL_SEND_DATA     : IN INTEGER RANGE 0 TO 5;
        VALUE_OF_X_RECEIVED : IN BIT;
        REQUEST_VALUE_OF_X : OUT BIT;
        OUT_BIN            : OUT SIGNED (24 - 1 DOWNTO 0);
        OUT_REAL           : OUT REAL 
  );
END COMPONENT MAC_SEN_POLY;
BEGIN
    MAC_INSTANCE : MAC_SEN_POLY
        GENERIC MAP (
            CI => CI, 
            CF => CF, 
            XI => XI, 
            XF => XF
    )
    PORT MAP (
        CLK                 => CLK_DUT,
        A                   => A_DUT,
        B                   => B_DUT,
        CTRL_SEND_DATA      => CTRL_SEND_DATA_DUT,
        OUT_BIN             => OUT_BIN_DUT,
        OUT_REAL            => OUT_REAL_DUT, 
        REQUEST_VALUE_OF_X  => REQUEST_VALUE_OF_X_DUT,
        VALUE_OF_X_RECEIVED => VALUE_OF_X_SENT_DUT       
    );
                    
    PROCESS(CLK_DUT)
    VARIABLE SIZE_X : INTEGER := XI + XF;
    VARIABLE SIZE_C : INTEGER := CI + CF;
    VARIABLE C1 : SIGNED (SIZE_C - 1 DOWNTO 0) := "00110010010000000";    -- (4.13) C1 = 0x6480  = 3,14065 
    VARIABLE C2 : SIGNED (SIZE_C - 1 DOWNTO 0) := "00000011001111011";    -- (4.13) C2 = 0xCF8   = 0,20263
    VARIABLE C3 : SIGNED (SIZE_C - 1 DOWNTO 0) := "10101010110011001";    -- (4.13) C3 = 0xF5599 = -5,325192
    VARIABLE C4 : SIGNED (SIZE_C - 1 DOWNTO 0) := "00001000101101110";    -- (4.13) C4 = 0x116E  = 0,544677 
    VARIABLE C5 : SIGNED (SIZE_C - 1 DOWNTO 0) := "00011100110011100";    -- (4.13) C5 = 0x399C  = 1,8003 
    -- VARIABLE IN_X2 : SIGNED (SIZE_X - 1 DOWNTO 0) := "0001100110011010";  -- test_2 X  = 0x199A  = 0,2
    -- VARIABLE IN_X3 : SIGNED (SIZE_X - 1 DOWNTO 0) := "0010101010011111";  -- test_3 X  = 0x2A9F  = 0,333
    -- VARIABLE IN_X4 : SIGNED (SIZE_X - 1 DOWNTO 0) := "0011010001111010";  -- test_4 X  = 0x347A  = 0,41
    
    VARIABLE IN_X1 : SIGNED (SIZE_X - 1 DOWNTO 0) := "0000000111111111";  -- test_1 X  =   = 0.031216 y = 0.0980
    VARIABLE IN_X2 : SIGNED (SIZE_X - 1 DOWNTO 0) := "1111110111111110";  -- test_4 X  =   = -0.0314
    VARIABLE IN_X3 : SIGNED (SIZE_X - 1 DOWNTO 0) := "1000111101111001";  -- test_3 X  =  = -1.7583
    VARIABLE IN_X4 : SIGNED (SIZE_X - 1 DOWNTO 0) := "1111110111111110";  -- test_3 X  =  = -0.0314
    VARIABLE IN_X5 : SIGNED (SIZE_X - 1 DOWNTO 0) := "0000000111111111";  -- test_1 X  =   = 0.031216
    VARIABLE IN_X6 : SIGNED (SIZE_X - 1 DOWNTO 0) := "0001101000111101";  -- test_5 X  =   = 0,41   y = 
    -- IN_X6 := "0001111000000110";    -- test_2 X  = 0x1E06  = 0,23456
    type s_type is (s_x1, s_x2, s_x3, s_x4, s_x5, s_x6, s_x_wait, s_t1, s_t2, s_t3, s_t4, s_t5, s_t6);
    VARIABLE x_state  : s_type := s_x6;
    VARIABLE vector_counter : INTEGER RANGE 0 TO 5 := 0;
    BEGIN 
        IF (CLK_DUT'event AND CLK_DUT = '1') THEN
            CASE vector_counter IS
                WHEN 0 => A_DUT <= C1;
                WHEN 1 => A_DUT <= C2;
                WHEN 2 => A_DUT <= C3;
                WHEN 3 => A_DUT <= C4;
                WHEN 4 => A_DUT <= C5;
                WHEN 5 => CTRL_SEND_DATA_DUT <= 5;
            END CASE;
            CTRL_SEND_DATA_DUT <= vector_counter;
            IF vector_counter < 5 THEN
                vector_counter := vector_counter + 1;
            END IF; 
            CASE x_state IS       
                WHEN s_x6 =>
                    VALUE_OF_X_SENT_DUT <= '0';
                    IF REQUEST_VALUE_OF_X_DUT = '1' THEN
                        B_DUT <= IN_X6;
                        VALUE_OF_X_SENT_DUT <= '1';
                        x_state := s_t6;
                    END IF;
                WHEN s_t6 =>
                    IF REQUEST_VALUE_OF_X_DUT = '0' THEN
                        VALUE_OF_X_SENT_DUT <= '0';
                        x_state := s_x5;
                    END IF; 
                WHEN s_x5 =>
                    IF REQUEST_VALUE_OF_X_DUT = '1' THEN
                        B_DUT  <= IN_X5;
                        VALUE_OF_X_SENT_DUT <= '1';
                        x_state := s_t5;
                    END IF;
                WHEN s_t5 =>
                    IF REQUEST_VALUE_OF_X_DUT = '0' THEN
                        VALUE_OF_X_SENT_DUT <= '0';
                        x_state := s_x4;
                    END IF;
                WHEN s_x4 =>
                    IF REQUEST_VALUE_OF_X_DUT = '1' THEN
                        B_DUT  <= IN_X4;
                        VALUE_OF_X_SENT_DUT <= '1';
                        x_state := s_t4;
                    END IF;
                WHEN s_t4 =>
                    IF REQUEST_VALUE_OF_X_DUT = '0' THEN
                        VALUE_OF_X_SENT_DUT <= '0';
                        x_state := s_x3;
                    END IF;
                WHEN s_x3 =>
                    IF REQUEST_VALUE_OF_X_DUT = '1' THEN
                        B_DUT  <= IN_X3;
                        VALUE_OF_X_SENT_DUT <= '1';
                        x_state := s_t3;
                    END IF;
                WHEN s_t3 =>
                    IF REQUEST_VALUE_OF_X_DUT = '0' THEN
                        VALUE_OF_X_SENT_DUT <= '0';
                        x_state := s_x2;
                    END IF;  
                WHEN s_x2 =>
                    IF REQUEST_VALUE_OF_X_DUT = '1' THEN
                        B_DUT  <= IN_X2;
                        VALUE_OF_X_SENT_DUT <= '1';
                        x_state := s_t2;
                    END IF;
                WHEN s_t2 =>
                    IF REQUEST_VALUE_OF_X_DUT = '0' THEN
                        VALUE_OF_X_SENT_DUT <= '0';
                        x_state := s_x1;
                    END IF;    
                WHEN s_x1 =>
                    IF REQUEST_VALUE_OF_X_DUT = '1' THEN
                        B_DUT  <= IN_X1;
                        VALUE_OF_X_SENT_DUT <= '1';
                        x_state := s_t1;
                    END IF;
                WHEN s_t1 =>
                    IF REQUEST_VALUE_OF_X_DUT = '0' THEN
                        VALUE_OF_X_SENT_DUT <= '0';
                        x_state := s_x6;
                    END IF;                 
                WHEN OTHERS =>
                    x_state := s_x_wait;
                END CASE;
        END IF;
    END PROCESS;
END COMPORTAMENTAL;
