LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY MotorPIDControl_tb IS
END MotorPIDControl_tb;

ARCHITECTURE Behavioral OF MotorPIDControl_tb IS
    -- Component Declaration
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

    -- Test Signals
    SIGNAL clock : std_logic := '0';
    SIGNAL reset : std_logic := '0';
    SIGNAL roll_kp, roll_ki, roll_kd : std_logic_vector(15 DOWNTO 0) := (others => '0');
    SIGNAL roll_setpoint, roll_actual : std_logic_vector(31 DOWNTO 0) := (others => '0');
    SIGNAL roll_output : std_logic_vector(31 DOWNTO 0);
    SIGNAL pitch_kp, pitch_ki, pitch_kd : std_logic_vector(15 DOWNTO 0) := (others => '0');
    SIGNAL pitch_setpoint, pitch_actual : std_logic_vector(31 DOWNTO 0) := (others => '0');
    SIGNAL pitch_output : std_logic_vector(31 DOWNTO 0);
    SIGNAL yaw_kp, yaw_ki, yaw_kd : std_logic_vector(15 DOWNTO 0) := (others => '0');
    SIGNAL yaw_setpoint, yaw_actual : std_logic_vector(31 DOWNTO 0) := (others => '0');
    SIGNAL yaw_output : std_logic_vector(31 DOWNTO 0);
    SIGNAL height_kp, height_ki, height_kd : std_logic_vector(15 DOWNTO 0) := (others => '0');
    SIGNAL height_setpoint, height_actual : std_logic_vector(31 DOWNTO 0) := (others => '0');
    SIGNAL height_output : std_logic_vector(31 DOWNTO 0);
    SIGNAL values_ready : std_logic;

    CONSTANT CLK_PERIOD : time := 10 ns;

    -- Helper procedure
    PROCEDURE print_height_test(
        test_name : in string;
        setpoint : in integer;
        actual : in integer;
        output : std_logic_vector(31 DOWNTO 0)
    ) IS
    BEGIN
        report "=== Test Case: " & test_name & " ===" severity note;
        report "Height Setpoint: " & integer'image(setpoint) severity note;
        report "Height Actual: " & integer'image(actual) severity note;
        report "Height Output: " & integer'image(to_integer(unsigned(output))) severity note;
        report "Values Ready: " & std_logic'image(values_ready) severity note;
    END PROCEDURE;

BEGIN
    -- DUT instantiation
    UUT: MotorPIDControl
    GENERIC MAP (
        data_width => 32,
        internal_width => 16
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
        WAIT FOR CLK_PERIOD * 10;
        reset <= '1';
        WAIT FOR CLK_PERIOD * 10;

        -- Test Case 1: Hover at fixed height
        height_setpoint <= x"00000800";  -- 2048
        height_actual <= x"00000400";    -- 1024
        height_kp <= x"0014";            -- Kp = 20
        height_ki <= x"0019";            -- Ki = 25
        height_kd <= x"0001";            -- Kd = 1
        WAIT FOR CLK_PERIOD * 100;       -- Increased wait time for settling
        print_height_test("Hover Height Control", 2048, 1024, height_output);

        -- Test Case 2: Ascend
        height_setpoint <= x"00000C00";  -- 3072
        height_actual <= x"00000800";    -- 2048
        WAIT FOR CLK_PERIOD * 100;
        print_height_test("Ascending", 3072, 2048, height_output);

        -- Test Case 3: Descend
        height_setpoint <= x"00000400";  -- 1024
        height_actual <= x"00000800";    -- 2048
        WAIT FOR CLK_PERIOD * 100;
        print_height_test("Descending", 1024, 2048, height_output);

        -- Test Case 4: Maximum Height
        height_setpoint <= x"00000FA0";  -- 4000
        height_actual <= x"00000000";    -- 0
        WAIT FOR CLK_PERIOD * 100;
        print_height_test("Maximum Height", 4000, 0, height_output);

        -- Test Case 5: Emergency Landing
        reset <= '0';
        WAIT FOR CLK_PERIOD * 20;
        print_height_test("Emergency Landing", 0, 0, height_output);

        REPORT "=== Test Complete ===" SEVERITY NOTE;
        WAIT;
    END PROCESS;

END Behavioral;