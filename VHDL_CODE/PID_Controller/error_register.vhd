library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity error_register is
    port (
        Error_in : in std_logic_vector(31 downto 0);
        Error_prev : out std_logic_vector(31 downto 0);
        trig : in std_logic 
    );
end error_register;

architecture Behavioral of error_register is 
begin
    process(trig)
    begin
        if rising_edge(trig) then
            Error_prev <= Error_in;
        end if;
    end process;
end Behavioral;

