library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Integration is
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
end Integration;

architecture Behavioral of Integration is
    signal acc_total, curr_err, new_acc, old_err, err_delta : INTEGER := 0;
    signal old_err_buff : std_logic_vector(31 DOWNTO 0) := (others => '0');
    
    component err_register
        port (
            Error_in : in std_logic_vector(31 downto 0);
            Error_prev : out std_logic_vector(31 downto 0);
            trig : in std_logic
        );
    end component;

begin
    ERR_FF : err_register
    port map (
        Error_in => error,
        Error_prev => old_err_buff,
        trig => trigger
    );

    process (ki_denominator, ki_numerator, time_for_divider, old_err_buff, trigger, sum, error, new_acc, err_delta)
    begin
        -- Convert inputs to integers
        acc_total <= to_integer(signed(sum));
        curr_err <= to_integer(signed(error));
        old_err <= to_integer(signed(old_err_buff));
        
        -- Check limits and set new_sum
        if new_acc < ((3072*to_integer(unsigned(ki_denominator))*to_integer(unsigned(time_for_divider)))/to_integer(unsigned(ki_numerator))) then
            new_sum <= std_logic_vector(to_signed(((3072*to_integer(unsigned(ki_denominator))*to_integer(unsigned(time_for_divider)))/to_integer(unsigned(ki_numerator))), 32));
        elsif new_acc > ((4000*to_integer(unsigned(ki_denominator))*to_integer(unsigned(time_for_divider)))/to_integer(unsigned(ki_numerator))) then
            new_sum <= std_logic_vector(to_signed(((4000*to_integer(unsigned(ki_denominator))*to_integer(unsigned(time_for_divider)))/to_integer(unsigned(ki_numerator))), 32));
        else
            new_sum <= std_logic_vector(to_signed(new_acc, 32));
        end if;

        error_difference <= std_logic_vector(to_signed(err_delta, 32));

        if rising_edge(trigger) then
            if integral_on = '1' then
                new_acc <= acc_total + curr_err;  -- Integration
            else
                new_acc <= 0;
            end if;
            err_delta <= curr_err - old_err;  -- Error difference calculation
            error_for_pid <= error;  -- Pass through error for PID
        end if;
    end process;

end Behavioral;