LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY FlightControlUnit IS
    GENERIC (
        data_width : INTEGER := 32;
        internal_width : INTEGER := 16;
        pwm_resolution : INTEGER := 12
    );
    PORT (
        -- System signals 
        clock : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        
        -- Control inputs
        roll_setpoint : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        pitch_setpoint : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        yaw_setpoint : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        height_setpoint : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        
        -- Sensor inputs
        roll_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        pitch_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        yaw_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        height_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        
        -- Motor outputs
        motor1_pwm, motor1_pwm_n : OUT STD_LOGIC;
        motor2_pwm, motor2_pwm_n : OUT STD_LOGIC;
        motor3_pwm, motor3_pwm_n : OUT STD_LOGIC;
        motor4_pwm, motor4_pwm_n : OUT STD_LOGIC;
        
        -- Status output
        system_ready : OUT STD_LOGIC
    );
END FlightControlUnit;

ARCHITECTURE Behavioral OF FlightControlUnit IS
    -- Internal signals for extended setpoints and actual values
    SIGNAL roll_setpoint_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL roll_actual_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pitch_setpoint_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pitch_actual_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL yaw_setpoint_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL yaw_actual_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL height_setpoint_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL height_actual_ext : STD_LOGIC_VECTOR(31 DOWNTO 0);
    
    SIGNAL roll_out, pitch_out, yaw_out, height_out : STD_LOGIC_VECTOR(data_width-1 DOWNTO 0);
    SIGNAL motor1_duty, motor2_duty, motor3_duty, motor4_duty : STD_LOGIC_VECTOR(pwm_resolution-1 DOWNTO 0);
    SIGNAL pid_ready : STD_LOGIC;

    -- Constants for PID gains
    CONSTANT KP : STD_LOGIC_VECTOR(internal_width-1 DOWNTO 0) := x"0014"; -- 20
    CONSTANT KI : STD_LOGIC_VECTOR(internal_width-1 DOWNTO 0) := x"0019"; -- 25
    CONSTANT KD : STD_LOGIC_VECTOR(internal_width-1 DOWNTO 0) := x"0001"; -- 1

    -- Component declarations
    COMPONENT MotorPIDControl IS
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
    END COMPONENT;

    COMPONENT PWMGeneratorMotor IS
        GENERIC (
            base_clock : INTEGER := 100000000;  -- 100MHz system clock
            pwm_frequency : INTEGER := 65;      -- 65Hz PWM frequency
            resolution : INTEGER := 12          -- 12-bit resolution
        );
        PORT (
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            
            -- Motor 1 control
            motor1_duty : IN STD_LOGIC_VECTOR(resolution-1 DOWNTO 0);
            motor1_pwm : OUT STD_LOGIC;
            motor1_pwm_n : OUT STD_LOGIC;

            -- Motor 2 control
            motor2_duty : IN STD_LOGIC_VECTOR(resolution-1 DOWNTO 0);
            motor2_pwm : OUT STD_LOGIC;
            motor2_pwm_n : OUT STD_LOGIC;

            -- Motor 3 control
            motor3_duty : IN STD_LOGIC_VECTOR(resolution-1 DOWNTO 0);
            motor3_pwm : OUT STD_LOGIC;
            motor3_pwm_n : OUT STD_LOGIC;

            -- Motor 4 control
            motor4_duty : IN STD_LOGIC_VECTOR(resolution-1 DOWNTO 0);
            motor4_pwm : OUT STD_LOGIC;
            motor4_pwm_n : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN
    -- Signal extension process
    PROCESS(roll_setpoint, roll_sensor, pitch_setpoint, pitch_sensor,
            yaw_setpoint, yaw_sensor, height_setpoint, height_sensor)
    BEGIN
        roll_setpoint_ext <= x"00000" & roll_setpoint;
        roll_actual_ext <= x"000000" & roll_sensor;
        pitch_setpoint_ext <= x"00000" & pitch_setpoint;
        pitch_actual_ext <= x"000000" & pitch_sensor;
        yaw_setpoint_ext <= x"00000" & yaw_setpoint;
        yaw_actual_ext <= x"000000" & yaw_sensor;
        height_setpoint_ext <= x"00000" & height_setpoint;
        height_actual_ext <= x"000000" & height_sensor;
    END PROCESS;

    -- PID controller instantiation
    pid_control : MotorPIDControl 
    GENERIC MAP (
        data_width => data_width,
        internal_width => internal_width
    )
    PORT MAP (
        clock => clock,
        reset => reset,
        -- Roll
        roll_kp => KP, roll_ki => KI, roll_kd => KD,
        roll_setpoint => roll_setpoint_ext,
        roll_actual => roll_actual_ext,
        roll_output => roll_out,
        -- Pitch
        pitch_kp => KP, pitch_ki => KI, pitch_kd => KD,
        pitch_setpoint => pitch_setpoint_ext,
        pitch_actual => pitch_actual_ext,
        pitch_output => pitch_out,
        -- Yaw
        yaw_kp => KP, yaw_ki => KI, yaw_kd => KD,
        yaw_setpoint => yaw_setpoint_ext,
        yaw_actual => yaw_actual_ext,
        yaw_output => yaw_out,
        -- Height
        height_kp => KP, height_ki => KI, height_kd => KD,
        height_setpoint => height_setpoint_ext,
        height_actual => height_actual_ext,
        height_output => height_out,
        values_ready => pid_ready
    );

    -- PWM generator instantiation
    pwm_gen : PWMGeneratorMotor
    GENERIC MAP (
        base_clock => 100000000,
        pwm_frequency => 65,
        resolution => pwm_resolution
    )
    PORT MAP (
        clock => clock,
        reset => reset,
        enable => pid_ready,
        motor1_duty => motor1_duty,
        motor1_pwm => motor1_pwm,
        motor1_pwm_n => motor1_pwm_n,
        motor2_duty => motor2_duty,
        motor2_pwm => motor2_pwm,
        motor2_pwm_n => motor2_pwm_n,
        motor3_duty => motor3_duty,
        motor3_pwm => motor3_pwm,
        motor3_pwm_n => motor3_pwm_n,
        motor4_duty => motor4_duty,
        motor4_pwm => motor4_pwm,
        motor4_pwm_n => motor4_pwm_n
    );

    -- Mix PID outputs to motor commands
    PROCESS(roll_out, pitch_out, yaw_out, height_out)
        VARIABLE roll, pitch, yaw, height : INTEGER;
    BEGIN
        roll := to_integer(unsigned(roll_out(11 DOWNTO 0)));
        pitch := to_integer(unsigned(pitch_out(11 DOWNTO 0)));
        yaw := to_integer(unsigned(yaw_out(11 DOWNTO 0)));
        height := to_integer(unsigned(height_out(11 DOWNTO 0)));

        -- Motor mixing algorithm
        motor1_duty <= std_logic_vector(to_unsigned(height + pitch + roll - yaw, 12));
        motor2_duty <= std_logic_vector(to_unsigned(height + pitch - roll + yaw, 12));
        motor3_duty <= std_logic_vector(to_unsigned(height - pitch - roll - yaw, 12));
        motor4_duty <= std_logic_vector(to_unsigned(height - pitch + roll + yaw, 12));
    END PROCESS;

    -- System ready signal
    system_ready <= pid_ready;

END Behavioral;