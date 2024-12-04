library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity tb_Integration is
end tb_Integration;

architecture Behavioral of tb_Integration is
    -- Component declaration
    component Integration
        port (
            ki_numerator : in std_logic_vector(15 downto 0);
            ki_denominator : in std_logic_vector(15 downto 0);
            time_for_divider : in std_logic_vector(15 downto 0);
            integral_on : in std_logic;
            trigger : in std_logic;
            sum : in std_logic_vector(31 downto 0);
            error : in std_logic_vector(31 downto 0);
            new_sum : out std_logic_vector(31 downto 0);
            error_difference : out std_logic_vector(31 downto 0);
            error_for_pid : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Test signals
    signal clk_period : time := 10 ns;
    signal ki_numerator : std_logic_vector(15 downto 0) := x"0001";
    signal ki_denominator : std_logic_vector(15 downto 0) := x"0001";
    signal time_for_divider : std_logic_vector(15 downto 0) := x"0001";
    signal integral_on : std_logic := '1';
    signal trigger : std_logic := '0';
    signal sum : std_logic_vector(31 downto 0) := (others => '0');
    signal error : std_logic_vector(31 downto 0) := (others => '0');
    signal new_sum : std_logic_vector(31 downto 0);
    signal error_difference : std_logic_vector(31 downto 0);
    signal error_for_pid : std_logic_vector(31 downto 0);

    -- Helper procedure for printing test results
    procedure print_test_case(
        test_name : in string;
        expected_sum : in integer;
        actual_sum : in std_logic_vector;
        expected_diff : in integer;
        actual_diff : in std_logic_vector) is
    begin
        report "Test Case: " & test_name;
        report "Expected sum: " & integer'image(expected_sum);
        report "Actual sum: " & integer'image(to_integer(signed(actual_sum)));
        report "Expected difference: " & integer'image(expected_diff);
        report "Actual difference: " & integer'image(to_integer(signed(actual_diff)));
        report "----------------------------------------";
    end procedure;

begin
    -- DUT instantiation
    DUT: Integration
    port map (
        ki_numerator => ki_numerator,
        ki_denominator => ki_denominator,
        time_for_divider => time_for_divider,
        integral_on => integral_on,
        trigger => trigger,
        sum => sum,
        error => error,
        new_sum => new_sum,
        error_difference => error_difference,
        error_for_pid => error_for_pid
    );

    -- Test process
    test_proc: process
    begin
        -- Test Case 1: Basic Integration
        sum <= x"00000020";  -- 32
        error <= x"00000010"; -- 16
        wait for clk_period;
        trigger <= '1';
        wait for clk_period;
        trigger <= '0';
        wait for clk_period;
        print_test_case("Basic Integration", 48, new_sum, 16, error_difference);

        -- Test Case 2: Integration Disabled
        integral_on <= '0';
        sum <= x"00000020";
        error <= x"00000010";
        wait for clk_period;
        trigger <= '1';
        wait for clk_period;
        trigger <= '0';
        wait for clk_period;
        print_test_case("Integration Disabled", 0, new_sum, 0, error_difference);

        -- Test Case 3: Upper Limit Test
        integral_on <= '1';
        ki_numerator <= x"0001";
        ki_denominator <= x"0002";
        time_for_divider <= x"0002";
        sum <= x"00002000";    -- 8192
        error <= x"00001000";  -- 4096
        wait for clk_period;
        trigger <= '1';
        wait for clk_period;
        trigger <= '0';
        wait for clk_period;
        print_test_case("Upper Limit Test", 16000, new_sum, 4096, error_difference);

        -- Test Case 4: Error Difference Calculation
        sum <= x"00000000";
        error <= x"00000020"; -- Set new error value
        wait for clk_period;
        trigger <= '1';
        wait for clk_period;
        trigger <= '0';
        wait for clk_period;
        error <= x"00000010"; -- Change error value
        wait for clk_period;
        trigger <= '1';
        wait for clk_period;
        trigger <= '0';
        wait for clk_period;
        print_test_case("Error Difference", 32, new_sum, -16, error_difference);

        report "All tests completed";
        wait;
    end process;

end Behavioral;