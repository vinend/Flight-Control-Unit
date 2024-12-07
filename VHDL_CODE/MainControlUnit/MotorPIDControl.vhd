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

    -- Internal signals for PID controllers
    SIGNAL roll_output_buf, pitch_output_buf, yaw_output_buf, height_output_buf : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');
    SIGNAL roll_ready, pitch_ready, yaw_ready, height_ready : STD_LOGIC := '0';
    
    -- Internal enable signals
    SIGNAL roll_en, pitch_en, yaw_en, height_en : STD_LOGIC := '1';  -- Default enabled

    -- Component declaration for PID_Controller
    COMPONENT PID_Controller IS
        GENERIC (
            N : INTEGER := 16  -- number of bits of PWM counter
        );
        PORT (
            kp_sw : IN std_logic;
            ki_sw : IN std_logic;
            kd_sw : IN std_logic;
            SetVal : IN std_logic_vector(11 DOWNTO 0);
            PWM_PIN : OUT std_logic;
            ADC : IN std_logic_vector(7 DOWNTO 0);
            reset_button : IN std_logic;
            display_output : OUT std_logic_vector(11 DOWNTO 0);
            clk : IN std_logic;
            anode_activate : OUT std_logic_vector(3 DOWNTO 0);
            led_out : OUT std_logic_vector(6 DOWNTO 0)
        );
    END COMPONENT;

BEGIN
    -- Enable signal generation
    roll_en <= '1' when to_integer(unsigned(roll_kp)) /= 0 else '0';
    pitch_en <= '1' when to_integer(unsigned(pitch_kp)) /= 0 else '0';
    yaw_en <= '1' when to_integer(unsigned(yaw_kp)) /= 0 else '0';
    height_en <= '1' when to_integer(unsigned(height_kp)) /= 0 else '0';

    -- Roll axis PID controller
    roll_pid : PID_Controller
    PORT MAP (
        kp_sw => roll_en,                -- Enable based on Kp value
        ki_sw => roll_en,                -- Use same enable for all terms
        kd_sw => roll_en,
        SetVal => roll_setpoint(11 DOWNTO 0),
        PWM_PIN => open,
        ADC => roll_actual(7 DOWNTO 0),
        reset_button => reset,
        display_output => roll_output_buf,
        clk => clock,
        anode_activate => open,
        led_out => open
    );
    roll_output <= x"00000" & roll_output_buf when roll_en = '1' else (others => '0');

    -- Pitch axis PID controller
    pitch_pid : PID_Controller
    PORT MAP (
        kp_sw => pitch_kp(15),
        ki_sw => pitch_ki(15),
        kd_sw => pitch_kd(15),
        SetVal => pitch_setpoint(11 DOWNTO 0),
        PWM_PIN => open,
        ADC => pitch_actual(7 DOWNTO 0),
        reset_button => reset,
        display_output => pitch_output_buf,
        clk => clock,
        anode_activate => open,
        led_out => open
    );
    pitch_output <= x"00000" & pitch_output_buf;

    -- Yaw axis PID controller
    yaw_pid : PID_Controller
    PORT MAP (
        kp_sw => yaw_kp(15),
        ki_sw => yaw_ki(15),
        kd_sw => yaw_kd(15),
        SetVal => yaw_setpoint(11 DOWNTO 0),
        PWM_PIN => open,
        ADC => yaw_actual(7 DOWNTO 0),
        reset_button => reset,
        display_output => yaw_output_buf,
        clk => clock,
        anode_activate => open,
        led_out => open
    );
    yaw_output <= x"00000" & yaw_output_buf;

    -- Height axis PID controller
    height_pid : PID_Controller
    PORT MAP (
        kp_sw => height_en,
        ki_sw => height_en,
        kd_sw => height_en,
        SetVal => height_setpoint(11 DOWNTO 0),
        PWM_PIN => open,
        ADC => height_actual(7 DOWNTO 0),
        reset_button => reset,
        display_output => height_output_buf,
        clk => clock,
        anode_activate => open,
        led_out => open
    );
    height_output <= x"00000" & height_output_buf when height_en = '1' else (others => '0');

    -- Process to handle values_ready signal
    ready_proc : PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '0' THEN
                values_ready <= '0';
            ELSE
                values_ready <= roll_en or pitch_en or yaw_en or height_en;
            END IF;
        END IF;
    END PROCESS;

END Behavioral;