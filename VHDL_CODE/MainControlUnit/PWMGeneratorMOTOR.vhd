LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PWMGeneratorMotor IS
    GENERIC (
        base_clock : INTEGER := 100000000;  -- 100MHz system clock
        pwm_frequency : INTEGER := 65;      -- 65Hz PWM frequency
        resolution : INTEGER := 12           -- 12-bit resolution
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
END PWMGeneratorMotor;

ARCHITECTURE Behavioral OF PWMGeneratorMotor IS
    -- Internal signals for PWM outputs
    SIGNAL pwm1_signal : STD_LOGIC := '0';
    SIGNAL pwm2_signal : STD_LOGIC := '0';
    SIGNAL pwm3_signal : STD_LOGIC := '0';
    SIGNAL pwm4_signal : STD_LOGIC := '0';

    -- Component declaration
    COMPONENT PWM_Generator
        PORT (
            enable : IN STD_LOGIC;
            duty_in : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            clock : IN STD_LOGIC;
            pwm_out : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN
    -- Motor 1 PWM instance
    pwm1 : PWM_Generator
    PORT MAP (
        enable => enable,
        duty_in => motor1_duty,
        clock => clock,
        pwm_out => pwm1_signal
    );
    -- Assign outputs using internal signal
    motor1_pwm <= pwm1_signal;
    motor1_pwm_n <= NOT pwm1_signal;

    -- Motor 2 PWM instance
    pwm2 : PWM_Generator
    PORT MAP (
        enable => enable,
        duty_in => motor2_duty,
        clock => clock,
        pwm_out => pwm2_signal
    );
    motor2_pwm <= pwm2_signal;
    motor2_pwm_n <= NOT pwm2_signal;

    -- Motor 3 PWM instance
    pwm3 : PWM_Generator
    PORT MAP (
        enable => enable,
        duty_in => motor3_duty,
        clock => clock,
        pwm_out => pwm3_signal
    );
    motor3_pwm <= pwm3_signal;
    motor3_pwm_n <= NOT pwm3_signal;

    -- Motor 4 PWM instance
    pwm4 : PWM_Generator
    PORT MAP (
        enable => enable,
        duty_in => motor4_duty,
        clock => clock,
        pwm_out => pwm4_signal
    );
    motor4_pwm <= pwm4_signal;
    motor4_pwm_n <= NOT pwm4_signal;

END Behavioral;