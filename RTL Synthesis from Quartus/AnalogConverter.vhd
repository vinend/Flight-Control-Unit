LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY AnalogConverter IS
    PORT (
        sys_clock    : IN STD_LOGIC;
        start_conv   : IN STD_LOGIC;
        conv_done    : OUT STD_LOGIC;
        adc_result   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        analog_pins  : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END AnalogConverter;

ARCHITECTURE Behavioral OF AnalogConverter IS
    -- Signal declarations
    SIGNAL counter : unsigned(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL conversion_in_progress : STD_LOGIC := '0';
    
BEGIN
    -- Simple ADC simulation process
    process(sys_clock)
    begin
        if rising_edge(sys_clock) then
            if start_conv = '1' and conversion_in_progress = '0' then
                -- Start new conversion
                conversion_in_progress <= '1';
                counter <= (others => '0');
                conv_done <= '0';
            elsif conversion_in_progress = '1' then
                -- Continue conversion
                if counter = 255 then  -- Conversion complete after 256 cycles
                    conversion_in_progress <= '0';
                    conv_done <= '1';
                    -- Simple conversion - just extend the input to 16 bits
                    adc_result <= analog_pins & x"00";
                else
                    counter <= counter + 1;
                end if;
            else
                conv_done <= '0';
            end if;
        end if;
    end process;

END Behavioral;