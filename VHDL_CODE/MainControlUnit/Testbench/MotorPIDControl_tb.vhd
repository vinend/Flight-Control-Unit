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
    
    -- PID gains (16-bit)
    SIGNAL roll_kp, roll_ki, roll_kd : std_logic_vector(15 DOWNTO 0) := (others => '0');
    SIGNAL pitch_kp, pitch_ki, pitch_kd : std_logic_vector(15 DOWNTO 0) := (others => '0');
    SIGNAL yaw_kp, yaw_ki, yaw_kd : std_logic_vector(15 DOWNTO 0) := (others => '0');
    SIGNAL height_kp, height_ki, height_kd : std_logic_vector(15 DOWNTO 0) := (others => '0');
    
    -- Setpoints and actual values (32-bit)
    SIGNAL roll_setpoint, roll_actual : std_logic_vector(31 DOWNTO 0) := (others => '0');
    SIGNAL pitch_setpoint, pitch_actual : std_logic_vector(31 DOWNTO 0) := (others => '0');
    SIGNAL yaw_setpoint, yaw_actual : std_logic_vector(31 DOWNTO 0) := (others => '0');
    SIGNAL height_setpoint, height_actual : std_logic_vector(31 DOWNTO 0) := (others => '0');
    
    -- Outputs (32-bit)
    SIGNAL roll_output, pitch_output : std_logic_vector(31 DOWNTO 0);
    SIGNAL yaw_output, height_output : std_logic_vector(31 DOWNTO 0);
    
    SIGNAL values_ready : std_logic;
    
    CONSTANT CLK_PERIOD : time := 10 ns;

    -- Helper procedure for printing test results
    PROCEDURE print_quad_test(
        test_name : in string;
        roll_sp, pitch_sp, yaw_sp, height_sp : in integer;
        roll_act, pitch_act, yaw_act, height_act : in integer;
        roll_out, pitch_out, yaw_out, height_out : in std_logic_vector(31 DOWNTO 0)
    ) IS
    BEGIN
        report "=== Test Case: " & test_name & " ===" severity note;
        report "Roll - SP:" & integer'image(roll_sp) & 
               " Act:" & integer'image(roll_act) & 
               " Out:" & integer'image(to_integer(unsigned(roll_out))) severity note;
        report "Pitch - SP:" & integer'image(pitch_sp) & 
               " Act:" & integer'image(pitch_act) & 
               " Out:" & integer'image(to_integer(unsigned(pitch_out))) severity note;
        report "Yaw - SP:" & integer'image(yaw_sp) & 
               " Act:" & integer'image(yaw_act) & 
               " Out:" & integer'image(to_integer(unsigned(yaw_out))) severity note;
        report "Height - SP:" & integer'image(height_sp) & 
               " Act:" & integer'image(height_act) & 
               " Out:" & integer'image(to_integer(unsigned(height_out))) severity note;
        report "Values Ready: " & std_logic'image(values_ready) severity note;
    END PROCEDURE;

BEGIN
    -- DUT instantiation
    UUT : MotorPIDControl
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
    stim_proc: PROCESS
    BEGIN
        -- Initial reset
        reset <= '0';
        WAIT FOR CLK_PERIOD * 10;
        reset <= '1';
        WAIT FOR CLK_PERIOD * 10;

        -- Set PID gains for all axes
        roll_kp <= x"0014";    -- Kp = 20
        roll_ki <= x"0019";    -- Ki = 25
        roll_kd <= x"0001";    -- Kd = 1
        
        pitch_kp <= x"0014";   
        pitch_ki <= x"0019";
        pitch_kd <= x"0001";
        
        yaw_kp <= x"0014";
        yaw_ki <= x"0019";
        yaw_kd <= x"0001";
        
        height_kp <= x"0014";
        height_ki <= x"0019";
        height_kd <= x"0001";

        -- Test Case 1: Hover (stable flight)
        roll_setpoint <= x"00000800";    -- 2048
        pitch_setpoint <= x"00000800";   -- 2048
        yaw_setpoint <= x"00000800";     -- 2048
        height_setpoint <= x"00000800";  -- 2048
        
        roll_actual <= x"00000400";      -- 1024
        pitch_actual <= x"00000400";     -- 1024
        yaw_actual <= x"00000400";       -- 1024
        height_actual <= x"00000400";    -- 1024
        
        WAIT FOR CLK_PERIOD * 100;
        print_quad_test("Hover", 2048, 2048, 2048, 2048,
                       1024, 1024, 1024, 1024,
                       roll_output, pitch_output, yaw_output, height_output);

        -- Test Case 2: Forward Tilt
        pitch_setpoint <= x"00000A00";   -- Pitch forward
        WAIT FOR CLK_PERIOD * 100;
        print_quad_test("Forward Tilt", 2048, 2560, 2048, 2048,
                       1024, 1024, 1024, 1024,
                       roll_output, pitch_output, yaw_output, height_output);

        -- Test Case 3: Right Roll
        roll_setpoint <= x"00000A00";    -- Roll right
        WAIT FOR CLK_PERIOD * 100;
        print_quad_test("Right Roll", 2560, 2560, 2048, 2048,
                       1024, 1024, 1024, 1024,
                       roll_output, pitch_output, yaw_output, height_output);

        -- Test Case 4: Yaw Turn
        yaw_setpoint <= x"00000C00";     -- Turn right
        WAIT FOR CLK_PERIOD * 100;
        print_quad_test("Yaw Turn", 2560, 2560, 3072, 2048,
                       1024, 1024, 1024, 1024,
                       roll_output, pitch_output, yaw_output, height_output);

        -- Test Case 5: Ascend
        height_setpoint <= x"00000C00";  -- Increase height
        WAIT FOR CLK_PERIOD * 100;
        print_quad_test("Ascending", 2560, 2560, 3072, 3072,
                       1024, 1024, 1024, 1024,
                       roll_output, pitch_output, yaw_output, height_output);

        -- Test Case 6: Return to Center
        roll_setpoint <= x"00000800";    -- 2048
        pitch_setpoint <= x"00000800";   -- 2048
        yaw_setpoint <= x"00000800";     -- 2048
        height_setpoint <= x"00000800";  -- 2048
        WAIT FOR CLK_PERIOD * 100;
        print_quad_test("Return to Center", 2048, 2048, 2048, 2048,
                       1024, 1024, 1024, 1024,
                       roll_output, pitch_output, yaw_output, height_output);

        -- Test Case 7: Emergency Landing
        reset <= '0';
        WAIT FOR CLK_PERIOD * 20;
        print_quad_test("Emergency Stop", 0, 0, 0, 0,
                       0, 0, 0, 0,
                       roll_output, pitch_output, yaw_output, height_output);

        REPORT "=== Test Complete ===" SEVERITY NOTE;
        WAIT;
    END PROCESS;

END Behavioral;