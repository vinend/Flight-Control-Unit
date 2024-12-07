LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.ENV.ALL;  -- Add this for stop procedure

ENTITY FlightControlUnit_tb IS
END FlightControlUnit_tb;

ARCHITECTURE Behavioral OF FlightControlUnit_tb IS
    -- Component Declaration
    COMPONENT FlightControlUnit IS
        GENERIC (
            data_width : INTEGER := 32;
            internal_width : INTEGER := 16;
            pwm_resolution : INTEGER := 12
        );
        PORT (
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
    END COMPONENT;

    -- Test Signals
    SIGNAL clock : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '0';
    
    -- Control setpoints
    SIGNAL roll_setpoint : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pitch_setpoint : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL yaw_setpoint : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL height_setpoint : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    
    -- Sensor inputs
    SIGNAL roll_sensor : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL pitch_sensor : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL yaw_sensor : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL height_sensor : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    
    -- Motor outputs
    SIGNAL motor1_pwm, motor1_pwm_n : STD_LOGIC;
    SIGNAL motor2_pwm, motor2_pwm_n : STD_LOGIC;
    SIGNAL motor3_pwm, motor3_pwm_n : STD_LOGIC;
    SIGNAL motor4_pwm, motor4_pwm_n : STD_LOGIC;
    
    -- Status
    SIGNAL system_ready : STD_LOGIC;
    
    -- Clock period and timing constants
    CONSTANT CLK_PERIOD : TIME := 10 ns;
    CONSTANT STABILIZATION_TIME : TIME := 10 us;    -- Shorter stabilization
    CONSTANT TEST_TIME : TIME := 50 us;            -- Longer test time
    CONSTANT EMERGENCY_TIME : TIME := 5 us;     -- Emergency response time

    -- Helper procedure for printing test results
    PROCEDURE print_test_case(
        test_name : IN STRING;
        m1, m2, m3, m4 : IN STD_LOGIC
    ) IS
    BEGIN
        REPORT "=== Test Case: " & test_name & " ===";
        REPORT "Motor 1 PWM: " & STD_LOGIC'image(m1);
        REPORT "Motor 2 PWM: " & STD_LOGIC'image(m2);
        REPORT "Motor 3 PWM: " & STD_LOGIC'image(m3);
        REPORT "Motor 4 PWM: " & STD_LOGIC'image(m4);
        REPORT "System Ready: " & STD_LOGIC'image(system_ready);
    END PROCEDURE;

    -- Procedure to inject periodic disturbances
    PROCEDURE inject_disturbance(
        SIGNAL sensor : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        base_value : IN INTEGER;
        amplitude : IN INTEGER) IS
    BEGIN
        sensor <= std_logic_vector(to_unsigned(base_value + amplitude, 8));
        WAIT FOR TEST_TIME/4;
        sensor <= std_logic_vector(to_unsigned(base_value - amplitude, 8));
        WAIT FOR TEST_TIME/4;
    END PROCEDURE;

BEGIN
    -- Component Instantiation
    UUT : FlightControlUnit
    GENERIC MAP (
        data_width => 32,
        internal_width => 16,
        pwm_resolution => 12
    )
    PORT MAP (
        clock => clock,
        reset => reset,
        roll_setpoint => roll_setpoint,
        pitch_setpoint => pitch_setpoint,
        yaw_setpoint => yaw_setpoint,
        height_setpoint => height_setpoint,
        roll_sensor => roll_sensor,
        pitch_sensor => pitch_sensor,
        yaw_sensor => yaw_sensor,
        height_sensor => height_sensor,
        motor1_pwm => motor1_pwm,
        motor1_pwm_n => motor1_pwm_n,
        motor2_pwm => motor2_pwm,
        motor2_pwm_n => motor2_pwm_n,
        motor3_pwm => motor3_pwm,
        motor3_pwm_n => motor3_pwm_n,
        motor4_pwm => motor4_pwm,
        motor4_pwm_n => motor4_pwm_n,
        system_ready => system_ready
    );

    -- Clock generation process
    clock_process : PROCESS
    BEGIN
        clock <= '0';
        WAIT FOR CLK_PERIOD/2;
        clock <= '1';
        WAIT FOR CLK_PERIOD/2;
    END PROCESS;

    -- Modified stimulus process
    stim_proc : PROCESS
    BEGIN
        -- Initial reset
        reset <= '0';
        WAIT FOR CLK_PERIOD * 10;
        reset <= '1';
        WAIT FOR STABILIZATION_TIME;

        -- Test Case 1: Hover condition with disturbance
        roll_setpoint <= x"400";  -- 1024 (mid-point)
        pitch_setpoint <= x"400"; 
        yaw_setpoint <= x"400";
        height_setpoint <= x"400";
        
        -- Initial sensor values
        roll_sensor <= x"40";     -- 64 (mid-point for 8-bit)
        pitch_sensor <= x"40";
        yaw_sensor <= x"40";
        height_sensor <= x"40";
        
        WAIT FOR TEST_TIME;
        print_test_case("Initial Hover", motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm);

        -- Test Case 2: Forward pitch with disturbance
        pitch_setpoint <= x"600";  -- Increase pitch
        FOR i IN 1 TO 4 LOOP
            inject_disturbance(pitch_sensor, 64, 16);  -- Add oscillation
        END LOOP;
        print_test_case("Forward Pitch", motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm);

        -- Test Case 3: Right roll with disturbance
        roll_setpoint <= x"600";   -- Roll right
        FOR i IN 1 TO 4 LOOP
            inject_disturbance(roll_sensor, 64, 16);
        END LOOP;
        print_test_case("Right Roll", motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm);

        -- Test Case 4: Yaw right with disturbance
        yaw_setpoint <= x"600";    -- Yaw right
        FOR i IN 1 TO 4 LOOP
            inject_disturbance(yaw_sensor, 64, 16);
        END LOOP;
        print_test_case("Yaw Right", motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm);

        -- Test Case 5: Increase height with disturbance
        height_setpoint <= x"600"; -- Increase altitude
        FOR i IN 1 TO 4 LOOP
            inject_disturbance(height_sensor, 64, 16);
        END LOOP;
        print_test_case("Ascending", motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm);

        -- Test Case 6: Emergency stop
        reset <= '0';
        WAIT FOR EMERGENCY_TIME;
        print_test_case("Emergency Stop", motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm);

        -- Test Case 7: Recovery with active control
        reset <= '1';
        roll_setpoint <= x"400";   -- Return to neutral
        pitch_setpoint <= x"400";
        yaw_setpoint <= x"400";
        height_setpoint <= x"400";
        
        -- Simulate recovery disturbance
        FOR i IN 1 TO 8 LOOP
            roll_sensor <= std_logic_vector(to_unsigned(48 + i*4, 8));
            pitch_sensor <= std_logic_vector(to_unsigned(48 + i*4, 8));
            WAIT FOR TEST_TIME/8;
        END LOOP;
        
        WAIT FOR TEST_TIME;
        print_test_case("Recovery", motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm);

        -- End simulation properly
        REPORT "=== Test Complete ===";
        WAIT FOR CLK_PERIOD * 10;  -- Allow for final prints
        std.env.stop;  -- Stop the simulation
        WAIT;
    END PROCESS;

    -- Add monitoring process for detailed debugging
    monitor_proc : PROCESS
    BEGIN
        WAIT FOR CLK_PERIOD;
        IF reset = '1' THEN
            REPORT "Current values:" &
                   " Roll SP: " & integer'image(to_integer(unsigned(roll_setpoint))) &
                   " Roll Act: " & integer'image(to_integer(unsigned(roll_sensor))) &
                   " M1:" & std_logic'image(motor1_pwm) &
                   " M2:" & std_logic'image(motor2_pwm) &
                   " M3:" & std_logic'image(motor3_pwm) &
                   " M4:" & std_logic'image(motor4_pwm);
        END IF;
    END PROCESS;

END Behavioral;