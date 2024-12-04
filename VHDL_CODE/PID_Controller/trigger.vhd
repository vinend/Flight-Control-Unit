LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY trigger IS
    PORT ( 
        adc_trigger_out : OUT STD_LOGIC;
        clock_in       : IN  STD_LOGIC
    );
END trigger;

ARCHITECTURE Behavioral OF trigger IS
    -- Counter signals for timing control
    SIGNAL inner_count : INTEGER := 0;
    SIGNAL outer_count : INTEGER := 0;
    
    -- Output buffer
    SIGNAL trigger_buffer : std_logic := '0';
    
    -- Constants for timing
    CONSTANT INNER_LIMIT : INTEGER := 50;
    CONSTANT TRIGGER_START : INTEGER := 9800;
    CONSTANT TRIGGER_END : INTEGER := 9803;
    
BEGIN
    trigger_process : PROCESS (clock_in)
    BEGIN
        -- Connect buffer to output
        adc_trigger_out <= trigger_buffer;
        
        IF rising_edge(clock_in) THEN
            -- Increment inner counter
            inner_count <= inner_count + 1;
            
            -- Check if inner counter reached limit
            IF inner_count = INNER_LIMIT THEN
                -- Reset inner counter and increment outer counter
                inner_count <= 0;
                outer_count <= outer_count + 1;
                
                -- Trigger control logic
                IF outer_count = TRIGGER_START THEN
                    trigger_buffer <= '1';
                ELSIF outer_count = TRIGGER_END THEN
                    -- Reset outer counter
                    outer_count <= 0;
                END IF;
            ELSE
                trigger_buffer <= '0';
            END IF;
        END IF;
    END PROCESS trigger_process;
    
END Behavioral;