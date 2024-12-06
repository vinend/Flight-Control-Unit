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
    -- Using your existing PID Controller component
    COMPONENT PID_Controller
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            p_en : IN STD_LOGIC;
            i_en : IN STD_LOGIC;
            d_en : IN STD_LOGIC;
            ref_val : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            adc_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            pwm : OUT STD_LOGIC;
            dbg_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;

    -- Internal signals for completion tracking
    SIGNAL roll_ready, pitch_ready, yaw_ready, height_ready : STD_LOGIC := '0';
    
    -- Enable signals for PID components
    SIGNAL roll_enables, pitch_enables, yaw_enables, height_enables : STD_LOGIC_VECTOR(2 DOWNTO 0);
    
BEGIN
    -- Roll axis PID controller
    roll_pid : PID_Controller
    PORT MAP (
        clk => clock,
        rst => reset,
        p_en => roll_enables(2),
        i_en => roll_enables(1),
        d_en => roll_enables(0),
        ref_val => roll_setpoint(11 DOWNTO 0),
        adc_in => roll_actual(7 DOWNTO 0),
        dbg_out => roll_output(11 DOWNTO 0)
    );

    -- Pitch axis PID controller
    pitch_pid : PID_Controller
    PORT MAP (
        clk => clock,
        rst => reset,
        p_en => pitch_enables(2),
        i_en => pitch_enables(1),
        d_en => pitch_enables(0),
        ref_val => pitch_setpoint(11 DOWNTO 0),
        adc_in => pitch_actual(7 DOWNTO 0),
        dbg_out => pitch_output(11 DOWNTO 0)
    );

    -- Yaw axis PID controller
    yaw_pid : PID_Controller
    PORT MAP (
        clk => clock,
        rst => reset,
        p_en => yaw_enables(2),
        i_en => yaw_enables(1),
        d_en => yaw_enables(0),
        ref_val => yaw_setpoint(11 DOWNTO 0),
        adc_in => yaw_actual(7 DOWNTO 0),
        dbg_out => yaw_output(11 DOWNTO 0)
    );

    -- Height axis PID controller
    height_pid : PID_Controller
    PORT MAP (
        clk => clock,
        rst => reset,
        p_en => height_enables(2),
        i_en => height_enables(1),
        d_en => height_enables(0),
        ref_val => height_setpoint(11 DOWNTO 0),
        adc_in => height_actual(7 DOWNTO 0),
        dbg_out => height_output(11 DOWNTO 0)
    );

    -- Process to handle enables and completion signals
    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '0' then
                values_ready <= '0';
                roll_ready <= '0';
                pitch_ready <= '0';
                yaw_ready <= '0';
                height_ready <= '0';
            else
                -- Enable signals based on PID constants
                roll_enables <= roll_kp(2 DOWNTO 0);
                pitch_enables <= pitch_kp(2 DOWNTO 0);
                yaw_enables <= yaw_kp(2 DOWNTO 0);
                height_enables <= height_kp(2 DOWNTO 0);
                
                -- Set values_ready when all axes are processed
                if roll_ready = '1' and pitch_ready = '1' and 
                   yaw_ready = '1' and height_ready = '1' then
                    values_ready <= '1';
                else
                    values_ready <= '0';
                end if;
            end if;
        end if;
    end process;

END Behavioral;