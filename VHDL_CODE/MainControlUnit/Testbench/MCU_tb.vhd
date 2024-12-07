LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;  -- Replace STD_LOGIC_ARITH with NUMERIC_STD
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY MCU_tb IS
END MCU_tb;

ARCHITECTURE Behavioral OF MCU_tb IS
    -- Constants
    CONSTANT CLK_PERIOD : TIME := 10 ns;

    -- Signals
    SIGNAL clock : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '0';
    SIGNAL start : STD_LOGIC := '0';
    SIGNAL roll_sensor, pitch_sensor, yaw_sensor, height_sensor : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL motor1_pwm, motor2_pwm, motor3_pwm, motor4_pwm : STD_LOGIC;
    SIGNAL state_out : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL ready : STD_LOGIC;

    -- Component declaration for the Main Control Unit
    COMPONENT MainControlUnit
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

    -- Procedure declaration in the declarative part
    PROCEDURE print_state(
        msg : IN STRING; 
        value : IN INTEGER; 
        state : IN STD_LOGIC_VECTOR(2 DOWNTO 0)
    ) IS
        VARIABLE state_str : STRING(1 TO 10);
    BEGIN
        CASE state IS
            WHEN "000" => state_str := "IDLE      ";
            WHEN "001" => state_str := "TAKEOFF   ";
            WHEN "010" => state_str := "HOVER     ";
            WHEN "011" => state_str := "CRUISE    ";
            WHEN "100" => state_str := "LAND      ";
            WHEN OTHERS => state_str := "UNKNOWN   ";
        END CASE;
        REPORT msg & ": " & INTEGER'IMAGE(value) & " State: " & state_str;
    END PROCEDURE print_state;

BEGIN
    -- Clock generation process
    clock_gen: PROCESS
    BEGIN
        WHILE TRUE LOOP
            clock <= '0';
            WAIT FOR CLK_PERIOD / 2;
            clock <= '1';
            WAIT FOR CLK_PERIOD / 2;
        END LOOP;
    END PROCESS;

    -- Instantiate the Unit Under Test (UUT)
    uut: MainControlUnit
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

    -- Test process
    stim_proc: PROCESS
    BEGIN
        -- Initialize inputs
        reset <= '0';
        start <= '0';
        roll_sensor <= (OTHERS => '0');
        pitch_sensor <= (OTHERS => '0');
        yaw_sensor <= (OTHERS => '0');
        height_sensor <= (OTHERS => '0');
        WAIT FOR CLK_PERIOD * 10;

        -- Apply reset
        reset <= '1';
        WAIT FOR CLK_PERIOD * 10;
        reset <= '0';
        WAIT FOR CLK_PERIOD * 10;

        -- Test Case 1: Idle state
        print_state("Initial State", 0, state_out);

        -- Test Case 2: Takeoff
        start <= '1';
        WAIT FOR CLK_PERIOD * 50;
        print_state("Takeoff Started", 0, state_out);

        -- Test Case 3: Hover
        WAIT FOR CLK_PERIOD * 100;
        print_state("Hovering", 0, state_out);

        -- Test Case 4: Cruise
        WAIT FOR CLK_PERIOD * 100;
        print_state("Cruising", 0, state_out);

        -- Test Case 5: Landing
        start <= '0';
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