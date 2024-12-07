LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY MainControlUnit IS
    PORT (
        clock : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        start : IN STD_LOGIC;  -- Start command
        
        -- Sensor inputs (8-bit ADC values)
        roll_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        pitch_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        yaw_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        height_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        
        -- Motor outputs
        motor1_pwm : OUT STD_LOGIC;  -- Front left
        motor2_pwm : OUT STD_LOGIC;  -- Front right
        motor3_pwm : OUT STD_LOGIC;  -- Rear left
        motor4_pwm : OUT STD_LOGIC;  -- Rear right
        
        -- Status outputs
        state_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        ready : OUT STD_LOGIC
    );
END MainControlUnit;

ARCHITECTURE Behavioral OF MainControlUnit IS
    -- Flight states
    TYPE state_type IS (IDLE, TAKEOFF, HOVER, CRUISE, LAND);
    SIGNAL current_state, next_state : state_type;
    
    -- Height setpoints for different states
    CONSTANT HOVER_HEIGHT : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000800";  -- 2048 (mid range)
    CONSTANT CRUISE_HEIGHT : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000A00"; -- 2560 (higher)
    CONSTANT LANDING_STEP : INTEGER := 100;
    
    -- PID signals
    SIGNAL pid_ready : STD_LOGIC;
    SIGNAL roll_out, pitch_out, yaw_out, height_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- Extended sensor signals
    SIGNAL roll_actual_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pitch_actual_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL yaw_actual_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL height_actual_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    -- PWM duty cycles
    SIGNAL motor1_duty, motor2_duty, motor3_duty, motor4_duty : STD_LOGIC_VECTOR(11 DOWNTO 0);
    
    -- Internal signals to mirror PWM values
    SIGNAL roll_sensor_internal, pitch_sensor_internal, yaw_sensor_internal, height_sensor_internal : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Component declarations
    COMPONENT MotorPIDControl IS
        GENERIC (
            data_width : INTEGER := 32;
            internal_width : INTEGER := 16
        );
        PORT (
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            roll_kp, roll_ki, roll_kd : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            roll_setpoint, roll_actual : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            roll_output : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            pitch_kp, pitch_ki, pitch_kd : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            pitch_setpoint, pitch_actual : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            pitch_output : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            yaw_kp, yaw_ki, yaw_kd : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            yaw_setpoint, yaw_actual : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            yaw_output : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            height_kp, height_ki, height_kd : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            height_setpoint, height_actual : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            height_output : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            values_ready : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT PWMGeneratorMotor IS
        PORT (
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            motor1_duty : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            motor1_pwm : OUT STD_LOGIC;
            motor2_duty : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            motor2_pwm : OUT STD_LOGIC;
            motor3_duty : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            motor3_pwm : OUT STD_LOGIC;
            motor4_duty : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            motor4_pwm : OUT STD_LOGIC
        );
    END COMPONENT;

    -- PID setpoint signals
    SIGNAL roll_setpoint, pitch_setpoint : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000800"; -- Neutral (2048)
    SIGNAL yaw_setpoint : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000800";  -- Neutral position
    SIGNAL height_setpoint : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0'); -- Start at 0
    
    -- PID gains (tuned for each state)
    SIGNAL roll_kp, roll_ki, roll_kd : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0014"; -- Default gains
    SIGNAL pitch_kp, pitch_ki, pitch_kd : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0014";
    SIGNAL yaw_kp, yaw_ki, yaw_kd : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0014";
    SIGNAL height_kp, height_ki, height_kd : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0014";

BEGIN
    -- Extend sensor inputs to 32 bits
    roll_actual_ext <= x"000000" & roll_sensor;
    pitch_actual_ext <= x"000000" & pitch_sensor;
    yaw_actual_ext <= x"000000" & yaw_sensor;
    height_actual_ext <= x"000000" & height_sensor;

    -- PID Controller instance
    pid_control : MotorPIDControl
    PORT MAP (
        clock => clock,
        reset => reset,
        roll_kp => roll_kp,
        roll_ki => roll_ki,
        roll_kd => roll_kd,
        roll_setpoint => roll_setpoint,
        roll_actual => roll_actual_ext,  -- Use extended signal
        roll_output => roll_out,
        pitch_kp => pitch_kp,
        pitch_ki => pitch_ki,
        pitch_kd => pitch_kd,
        pitch_setpoint => pitch_setpoint,
        pitch_actual => pitch_actual_ext,  -- Use extended signal
        pitch_output => pitch_out,
        yaw_kp => yaw_kp,
        yaw_ki => yaw_ki,
        yaw_kd => yaw_kd,
        yaw_setpoint => yaw_setpoint,
        yaw_actual => yaw_actual_ext,  -- Use extended signal
        yaw_output => yaw_out,
        height_kp => height_kp,
        height_ki => height_ki,
        height_kd => height_kd,
        height_setpoint => height_setpoint,
        height_actual => height_actual_ext,  -- Use extended signal
        height_output => height_out,
        values_ready => pid_ready
    );

    -- PWM Generator instance
    pwm_gen : PWMGeneratorMotor
    PORT MAP (
        clock => clock,
        reset => reset,
        enable => '1',
        motor1_duty => motor1_duty,
        motor1_pwm => motor1_pwm,
        motor2_duty => motor2_duty,
        motor2_pwm => motor2_pwm,
        motor3_duty => motor3_duty,
        motor3_pwm => motor3_pwm,
        motor4_duty => motor4_duty,
        motor4_pwm => motor4_pwm
    );

    -- State machine process
    state_proc: PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '0' THEN
                current_state <= IDLE;
                height_setpoint <= (others => '0');
            ELSE
                current_state <= next_state;
                
                CASE current_state IS
                    WHEN IDLE =>
                        IF start = '1' THEN
                            next_state <= TAKEOFF;
                        END IF;
                        
                    WHEN TAKEOFF =>
                        height_setpoint <= HOVER_HEIGHT;
                        IF unsigned(height_out) >= unsigned(HOVER_HEIGHT) THEN
                            next_state <= HOVER;
                        END IF;
                        
                    WHEN HOVER =>
                        IF start = '0' THEN
                            next_state <= LAND;
                        ELSIF unsigned(height_out) >= unsigned(CRUISE_HEIGHT) THEN
                            next_state <= CRUISE;
                        END IF;
                        
                    WHEN CRUISE =>
                        IF start = '0' OR unsigned(height_out) < unsigned(CRUISE_HEIGHT) THEN
                            next_state <= HOVER;
                        END IF;
                        
                    WHEN LAND =>
                        IF unsigned(height_out) > 0 THEN
                            height_setpoint <= std_logic_vector(unsigned(height_setpoint) - LANDING_STEP);
                        ELSE
                            next_state <= IDLE;
                        END IF;
                        
                    WHEN OTHERS =>
                        next_state <= IDLE;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- Motor mixing process
    motor_mix: PROCESS(roll_out, pitch_out, yaw_out, height_out)
        VARIABLE roll_val, pitch_val, yaw_val, height_val : INTEGER;
    BEGIN
        -- Convert outputs to integers
        roll_val := to_integer(signed(roll_out(11 DOWNTO 0)));
        pitch_val := to_integer(signed(pitch_out(11 DOWNTO 0)));
        yaw_val := to_integer(signed(yaw_out(11 DOWNTO 0)));
        height_val := to_integer(signed(height_out(11 DOWNTO 0)));
        
        -- Mix outputs for each motor
        -- Motor 1 (Front Left)
        motor1_duty <= std_logic_vector(to_unsigned(
            height_val + pitch_val - roll_val - yaw_val, 12));
            
        -- Motor 2 (Front Right)
        motor2_duty <= std_logic_vector(to_unsigned(
            height_val + pitch_val + roll_val + yaw_val, 12));
            
        -- Motor 3 (Rear Left)
        motor3_duty <= std_logic_vector(to_unsigned(
            height_val - pitch_val - roll_val + yaw_val, 12));
            
        -- Motor 4 (Rear Right)
        motor4_duty <= std_logic_vector(to_unsigned(
            height_val - pitch_val + roll_val - yaw_val, 12));
    END PROCESS;

    -- Output current state
    state_out <= "000" WHEN current_state = IDLE ELSE
                "001" WHEN current_state = TAKEOFF ELSE
                "010" WHEN current_state = HOVER ELSE
                "011" WHEN current_state = CRUISE ELSE
                "100" WHEN current_state = LAND ELSE
                "111";  
                
    -- Set ready signal
    ready <= pid_ready WHEN current_state /= IDLE ELSE '0';

    -- Mirror PWM values to internal signals
    roll_sensor_internal <= motor1_duty(7 DOWNTO 0);
    pitch_sensor_internal <= motor2_duty(7 DOWNTO 0);
    yaw_sensor_internal <= motor3_duty(7 DOWNTO 0);
    height_sensor_internal <= motor4_duty(7 DOWNTO 0);

END Behavioral;