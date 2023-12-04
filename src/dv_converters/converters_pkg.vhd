LIBRARY dv_converters;
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE converters_signed_to_real_pkg IS
    FUNCTION signed_to_frac (vec : SIGNED) RETURN REAL;
    FUNCTION signed_to_int  (vec : SIGNED) RETURN REAL;
    PROCEDURE convert_signed_to_real(
        A           : IN  SIGNED;
        I,F         : IN  INTEGER;
        OUT_REAL    : OUT REAL
    );
END converters_signed_to_real_pkg;

PACKAGE BODY converters_signed_to_real_pkg IS

    FUNCTION signed_to_frac(vec : SIGNED) RETURN REAL IS
        VARIABLE tmp_decimal_frac : REAL := 0.0;
        VARIABLE potencia : REAL := 0.5; -- Começa com 2^-1
    BEGIN
        tmp_decimal_frac := 0.0;
        FOR i IN vec'HIGH DOWNTO vec'LOW LOOP
            IF vec(i) = '1' THEN
                tmp_decimal_frac := tmp_decimal_frac + potencia;
            END IF; 
            potencia := potencia / 2.0;   
        END LOOP;
        RETURN tmp_decimal_frac;
    END signed_to_frac;

    FUNCTION signed_to_int(vec : SIGNED) RETURN REAL IS
        VARIABLE tmp_decimal_int, pot : REAL := 0.0;
        VARIABLE j : INTEGER := 0;
    BEGIN 
        tmp_decimal_int := 0.0;
        pot := 0.0;
        j := 0;
        FOR i IN vec'LOW TO vec'HIGH LOOP
            IF vec(i) = '1' THEN
                IF i = vec'HIGH THEN
                    pot := REAL(2**j) * (-1.0); -- CORREÇÃO
                ELSE 
                    pot := REAL(2**j);
                END IF;
                tmp_decimal_int := tmp_decimal_int + pot;
            END IF;
            j := j + 1;
        END LOOP;
        RETURN tmp_decimal_int;
    END signed_to_int;

    PROCEDURE convert_signed_to_real(
        A           : IN  SIGNED;
        I,F         : IN  INTEGER;
        OUT_REAL    : OUT REAL
        ) IS
        VARIABLE val_int            : SIGNED(I - 1 DOWNTO 0);
        VARIABLE val_frac           : SIGNED(F - 1 DOWNTO 0);
        VARIABLE OUT_FRAC, OUT_INT  : REAL := 0.0;
        BEGIN 
            OUT_INT := 0.0;
            OUT_FRAC := 0.0;
            val_int := A(A'HIGH DOWNTO A'HIGH - (I - 1));
            OUT_INT := signed_to_int(val_int);
            val_frac := A(A'HIGH - I DOWNTO A'LOW);
            OUT_FRAC := signed_to_frac(val_frac);
            OUT_REAL := OUT_INT + OUT_FRAC;
    END convert_signed_to_real;

END converters_signed_to_real_pkg;
