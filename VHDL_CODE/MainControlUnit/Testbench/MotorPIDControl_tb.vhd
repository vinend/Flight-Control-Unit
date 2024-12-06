LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY MotorPIDControl_tb IS
END MotorPIDControl_tb;

ARCHITECTURE Behavioral OF MotorPIDControl_tb IS
    -- Component Declaration
    COMPONENT MotorPIDControl
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

    -- Constants
    CONSTANT CLK_PERIOD : TIME := 10 ns;
    CONSTANT DATA_WIDTH : INTEGER := 32;
    CONSTANT INTERNAL_WIDTH : INTEGER := 16;

    -- Test Signals
    SIGNAL clock : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '0';
    
    -- PID Constants
    SIGNAL roll_kp, roll_ki, roll_kd : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0014"; -- 20 in hex
    SIGNAL pitch_kp, pitch_ki, pitch_kd : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0014";
    SIGNAL yaw_kp, yaw_ki, yaw_kd : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0014";
    SIGNAL height_kp, height_ki, height_kd : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0014";
    
    -- Setpoints and Actual Values
    SIGNAL roll_setpoint, roll_actual : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    SIGNAL pitch_setpoint, pitch_actual : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    SIGNAL yaw_setpoint, yaw_actual : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    SIGNAL height_setpoint, height_actual : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    
    -- Outputs
    SIGNAL roll_output : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL pitch_output : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL yaw_output : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL height_output : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL values_ready : STD_LOGIC;

    -- Procedure for printing test results
    PROCEDURE print_height_test(
        test_name : STRING;
        setpoint : INTEGER;
        actual : INTEGER;
        output : STD_LOGIC_VECTOR(31 DOWNTO 0)
    ) IS
    BEGIN
        REPORT "=== Test Case: " & test_name & " ===" SEVERITY NOTE;
        REPORT "Height Setpoint: " & INTEGER'IMAGE(setpoint) SEVERITY NOTE;
        REPORT "Height Actual: " & INTEGER'IMAGE(actual) SEVERITY NOTE;
        REPORT "Height Output: " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(output))) SEVERITY NOTE;
        REPORT "Values Ready: " & STD_LOGIC'IMAGE(values_ready) SEVERITY NOTE;
    END PROCEDURE;

BEGIN
    -- DUT instantiation
    UUT : MotorPIDControl
    GENERIC MAP (
        data_width => DATA_WIDTH,
        internal_width => INTERNAL_WIDTH
    )
    PORT MAP (
        clock => clock,
        reset => reset,
        roll_kp => roll_kp,
        roll_ki => roll_ki,
        roll_kd => roll_kd,
        roll_setpoint => roll_setpoint,
        roll_actual => roll_actual,
        roll_output => roll_output,
        pitch_kp => pitch_kp,
        pitch_ki => pitch_ki,
        pitch_kd => pitch_kd,
        pitch_setpoint => pitch_setpoint,
        pitch_actual => pitch_actual,
        pitch_output => pitch_output,
        yaw_kp => yaw_kp,
        yaw_ki => yaw_ki,
        yaw_kd => yaw_kd,
        yaw_setpoint => yaw_setpoint,
        yaw_actual => yaw_actual,
        yaw_output => yaw_output,
        height_kp => height_kp,
        height_ki => height_ki,
        height_kd => height_kd,
        height_setpoint => height_setpoint,
        height_actual => height_actual,
        height_output => height_output,
        values_ready => values_ready
    );

    -- Clock generation
    clock_process : PROCESS
    BEGIN
        clock <= '0';
        WAIT FOR CLK_PERIOD/2;
        clock <= '1';
        WAIT FOR CLK_PERIOD/2;
    END PROCESS;

    -- Stimulus process
    stim_proc : PROCESS
    BEGIN
        -- Initial reset
        reset <= '0';
        WAIT FOR CLK_PERIOD * 2;
        reset <= '1';
        WAIT FOR CLK_PERIOD * 2;

        -- Test Case 1: Hover at fixed height
        height_setpoint <= x"00000800"; -- 2048 (middle height)
        height_actual <= x"00000400";   -- 1024 (lower than setpoint)
        WAIT FOR CLK_PERIOD * 10;
        print_height_test("Hover Height Control", 2048, 1024, height_output);

        -- Test Case 2: Ascend
        height_setpoint <= x"00000C00"; -- 3072 (75% height)
        height_actual <= x"00000800";   -- 2048 (current height)
        WAIT FOR CLK_PERIOD * 10;
        print_height_test("Ascending", 3072, 2048, height_output);

        -- Test Case 3: Descend
        height_setpoint <= x"00000400"; -- 1024 (25% height)
        height_actual <= x"00000800";   -- 2048 (current height)
        WAIT FOR CLK_PERIOD * 10;
        print_height_test("Descending", 1024, 2048, height_output);

        -- Test Case 4: Maximum Height
        height_setpoint <= x"00000FA0"; -- 4000 (max height)
        height_actual <= x"00000000";   -- 0 (ground level)
        WAIT FOR CLK_PERIOD * 10;
        print_height_test("Maximum Height", 4000, 0, height_output);

        -- Test Case 5: Emergency Landing (Reset)
        reset <= '0';
        WAIT FOR CLK_PERIOD * 5;
        print_height_test("Emergency Landing", 0, 0, height_output);

        REPORT "=== Test Complete ===" SEVERITY NOTE;
        WAIT;
    END PROCESS;

END Behavioral;