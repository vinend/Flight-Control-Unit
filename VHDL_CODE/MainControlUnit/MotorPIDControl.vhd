LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY MotorPIDControl IS
    GENERIC (
        data_width : INTEGER := 32;
        internal_width : INTEGER := 16
    );
    PORT (
        clock : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        
        -- Roll axis
        roll_kp, roll_ki, roll_kd : IN STD_LOGIC_VECTOR(internal_width-1 DOWNTO 0);
        roll_setpoint, roll_actual : IN STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
        roll_output : OUT STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
        
        -- Pitch axis
        pitch_kp, pitch_ki, pitch_kd : IN STD_LOGIC_VECTOR(internal_width-1 DOWNTO 0);
        pitch_setpoint, pitch_actual : IN STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
        pitch_output : OUT STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
        
        -- Yaw axis
        yaw_kp, yaw_ki, yaw_kd : IN STD_LOGIC_VECTOR(internal_width-1 DOWNTO 0);
        yaw_setpoint, yaw_actual : IN STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
        yaw_output : OUT STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
        
        -- Height axis
        height_kp, height_ki, height_kd : IN STD_LOGIC_VECTOR(internal_width-1 DOWNTO 0);
        height_setpoint, height_actual : IN STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
        height_output : OUT STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
        
        values_ready : OUT STD_LOGIC
    );
END MotorPIDControl;

ARCHITECTURE Behavioral OF MotorPIDControl IS
    -- Constants for scaling
    CONSTANT OUTPUT_SCALE : INTEGER := 4096;  -- 12-bit output scale
    CONSTANT KP_SCALE : INTEGER := 100;
    CONSTANT KI_SCALE : INTEGER := 100;
    CONSTANT KD_SCALE : INTEGER := 100;
    
    -- Internal signals with proper initialization
    SIGNAL height_error : INTEGER := 0;
    SIGNAL height_integral : INTEGER := 0;
    SIGNAL height_derivative : INTEGER := 0;
    SIGNAL height_prev_error : INTEGER := 0;
    SIGNAL height_output_temp : INTEGER := 0;

BEGIN
    -- Height control process
    height_control: PROCESS(clock)
        VARIABLE p_term, i_term, d_term : INTEGER := 0;
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '0' THEN
                height_error <= 0;
                height_integral <= 0;
                height_derivative <= 0;
                height_prev_error <= 0;
                height_output_temp <= 0;
                height_output <= (others => '0');
                values_ready <= '0';
            ELSE
                -- Calculate error (use only lower 12 bits)
                height_error <= to_integer(signed(height_setpoint(11 DOWNTO 0))) - 
                              to_integer(signed(height_actual(11 DOWNTO 0)));

                -- Calculate P term
                p_term := (to_integer(signed(height_kp)) * height_error) / KP_SCALE;

                -- Calculate I term
                IF height_integral < -OUTPUT_SCALE THEN
                    height_integral <= -OUTPUT_SCALE;
                ELSIF height_integral > OUTPUT_SCALE THEN
                    height_integral <= OUTPUT_SCALE;
                ELSE
                    height_integral <= height_integral + height_error;
                END IF;
                i_term := (to_integer(signed(height_ki)) * height_integral) / KI_SCALE;

                -- Calculate D term
                height_derivative <= height_error - height_prev_error;
                d_term := (to_integer(signed(height_kd)) * height_derivative) / KD_SCALE;
                height_prev_error <= height_error;

                -- Sum PID terms
                height_output_temp <= p_term + i_term + d_term;

                -- Saturate output
                IF height_output_temp > OUTPUT_SCALE THEN
                    height_output <= std_logic_vector(to_signed(OUTPUT_SCALE, data_width));
                ELSIF height_output_temp < 0 THEN
                    height_output <= (others => '0');
                ELSE
                    height_output <= std_logic_vector(to_signed(height_output_temp, data_width));
                END IF;

                values_ready <= '1';
            END IF;
        END IF;
    END PROCESS;

    -- Similar processes for roll, pitch and yaw control...

END Behavioral;