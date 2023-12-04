-- Felipe Ferreira Nascimento
-- Descrição para teste de pacote na conversão do tipo bits em ponto fixo para real.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY dv_converters;
USE dv_converters.converters_signed_to_real_pkg.ALL; -- pacote para conversao

ENTITY TESTE_PKG_CONVERTERS IS
  generic (
    I     : INTEGER := 6; -- qtd de bits parte inteira
    F     : INTEGER := 18 -- qtd de bits parte fracionaria
  );  
  PORT ( A            : IN  SIGNED (((I + F) - 1) DOWNTO 0); -- Vetor de Bits em ponto fixo
         OUT_REAL     : OUT REAL -- Valor no formato REAL.,
  );
END TESTE_PKG_CONVERTERS;

ARCHITECTURE exemplo OF TESTE_PKG_CONVERTERS IS
SIGNAL local_I : INTEGER := I;
SIGNAL local_F : INTEGER := F;
BEGIN
  PROCESS(A)
  VARIABLE t_out_real : REAL;
    BEGIN
      convert_signed_to_real(A, local_I, local_F, t_out_real);
      OUT_REAL <= t_out_real;
    END PROCESS;
END exemplo;