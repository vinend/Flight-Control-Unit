LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY MainControlUnit_tb IS
END MainControlUnit_tb;

ARCHITECTURE Behavioral OF MainControlUnit_tb IS
    -- Component Declaration
    COMPONENT MainControlUnit IS
        PORT (
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            start : IN STD_LOGIC;
            roll_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            pitch_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            yaw_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            height_sensor : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            motor1_pwm : OUT STD_LOGIC;
            motor2_pwm : OUT STD_LOGIC;
            motor3_pwm : OUT STD_LOGIC;
            motor4_pwm : OUT STD_LOGIC;
            state_out : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            ready : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Test Signals
    SIGNAL clock : std_logic := '0';
    SIGNAL reset : std_logic := '0';
    SIGNAL start : std_logic := '0';
    SIGNAL roll_sensor : std_logic_vector(7 DOWNTO 0) := (others => '0');
    SIGNAL pitch_sensor : std_logic_vector(7 DOWNTO 0) := (others => '0');
    SIGNAL yaw_sensor : std_logic_vector(7 DOWNTO 0) := (others => '0');
    SIGNAL height_sensor : std_logic_vector(7 DOWNTO 0) := (others => '0');
    SIGNAL motor1_pwm : std_logic;
    SIGNAL motor2_pwm : std_logic;
    SIGNAL motor3_pwm : std_logic;
    SIGNAL motor4_pwm : std_logic;
    SIGNAL state_out : std_logic_vector(2 DOWNTO 0);
    SIGNAL ready : std_logic;

    -- Clock period definition
    CONSTANT CLK_PERIOD : time := 10 ns;

    -- Helper procedure for printing state and motor outputs
    PROCEDURE print_state(
        test_name : in string;
        height : in integer;
        state : in std_logic_vector(2 DOWNTO 0)
    ) IS
        VARIABLE state_str : string(1 to 7);
    BEGIN
        CASE state IS
            WHEN "000" => state_str := "IDLE   ";
            WHEN "001" => state_str := "TAKEOFF";
            WHEN "010" => state_str := "HOVER  ";
            WHEN "011" => state_str := "CRUISE ";
            WHEN "100" => state_str := "LAND   ";
            WHEN OTHERS => state_str := "UNKNOWN";
        END CASE;

        report "=== Test Case: " & test_name & " ===" severity note;
        report "Current State: " & state_str severity note;
        report "Height Sensor: " & integer'image(to_integer(unsigned(height_sensor))) severity note;
        report "Motors - M1:" & std_logic'image(motor1_pwm) & 
               " M2:" & std_logic'image(motor2_pwm) & 
               " M3:" & std_logic'image(motor3_pwm) & 
               " M4:" & std_logic'image(motor4_pwm) severity note;
        report "Ready: " & std_logic'image(ready) severity note;
    END PROCEDURE;

BEGIN
    -- Instantiate the Unit Under Test (UUT)
    UUT: MainControlUnit 
    PORT MAP (
        clock => clock,
        reset => reset,
        start => start,
        roll_sensor => roll_sensor,
        pitch_sensor => pitch_sensor,
        yaw_sensor => yaw_sensor,
        height_sensor => height_sensor,
        motor1_pwm => motor1_pwm,
        motor2_pwm => motor2_pwm,
        motor3_pwm => motor3_pwm,
        motor4_pwm => motor4_pwm,
        state_out => state_out,
        ready => ready
    );

    -- Clock process
    clock_process: PROCESS
    BEGIN
        clock <= '0';
        WAIT FOR CLK_PERIOD/2;
        clock <= '1';
        WAIT FOR CLK_PERIOD/2;
    END PROCESS;

    -- Stimulus process
    stim_proc: PROCESS
    BEGIN
        -- Initial reset
        reset <= '0';
        WAIT FOR CLK_PERIOD * 10;
        reset <= '1';
        WAIT FOR CLK_PERIOD * 10;
        print_state("Initial IDLE", 0, state_out);

        -- Test Case 1: Takeoff
        start <= '1';
        height_sensor <= x"00";  -- Starting at ground level
        WAIT FOR CLK_PERIOD * 100;
        print_state("Takeoff Started", 0, state_out);

        -- Simulate ascending
        FOR i IN 0 TO 255 LOOP
            height_sensor <= std_logic_vector(to_unsigned(i, 8));
            WAIT FOR CLK_PERIOD * 10;
            IF i = 128 THEN  -- Mid-height
                print_state("Mid Takeoff", i, state_out);
            END IF;
        END LOOP;

        -- Test Case 2: Hover
        height_sensor <= x"80";  -- Maintain hover height
        WAIT FOR CLK_PERIOD * 100;
        print_state("Hovering", 128, state_out);

        -- Test Case 3: Attitude Control
        -- Roll right
        roll_sensor <= x"A0";
        WAIT FOR CLK_PERIOD * 50;
        print_state("Roll Right", 128, state_out);

        -- Pitch forward
        roll_sensor <= x"80";
        pitch_sensor <= x"A0";
        WAIT FOR CLK_PERIOD * 50;
        print_state("Pitch Forward", 128, state_out);

        -- Yaw rotation
        pitch_sensor <= x"80";
        yaw_sensor <= x"A0";
        WAIT FOR CLK_PERIOD * 50;
        print_state("Yaw Rotation", 128, state_out);

        -- Test Case 4: Cruise
        height_sensor <= x"C0";  -- Increase height
        WAIT FOR CLK_PERIOD * 100;
        print_state("Cruising", 192, state_out);

        -- Test Case 5: Landing
        start <= '0';  -- Initiate landing
        WAIT FOR CLK_PERIOD * 50;
        print_state("Landing Started", 192, state_out);

        -- Simulate descending
        FOR i IN 192 DOWNTO 0 LOOP
            height_sensor <= std_logic_vector(to_unsigned(i, 8));
            WAIT FOR CLK_PERIOD * 2;
            IF i = 96 THEN  -- Mid descent
                print_state("Mid Landing", i, state_out);
            END IF;
        END LOOP;

        -- Test Case 6: Emergency Stop
        start <= '1';
        height_sensor <= x"80";
        WAIT FOR CLK_PERIOD * 50;
        reset <= '0';  -- Emergency stop
        WAIT FOR CLK_PERIOD * 20;
        print_state("Emergency Stop", 128, state_out);

        report "=== Test Complete ===" severity note;
        wait;
    END PROCESS;

END Behavioral;