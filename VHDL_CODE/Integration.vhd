library library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Integration is
    port (
        ki_numerator : in std_logic_vector(15 downto 0);
        ki_denominator : in std_logic_vector(15 downto 0);
        time_for_divider : in std_logic_vector(15 downto 0);
        integral_on : in std_logic;
        trigger : in std_logic;
        saturateum : in std_logic_vector(31 downto 0);
        error : in std_logic_vector(31 downto 0);
        new_sum : out std_logic_vector(31 downto 0);
        error_difference : in std_logic_vector(31 downto 0);
        error_for_pid : out std_logic_vector(31 downto 0);
        
    );
end Integration;

architecture Behavioral of Integration is
    -- Internal signals
    signal acc_total, curr_err, new_acc, prev_err, err_delta : integer := 0;
    signal prev_err_reg : std_logic_vector(31 downto 0) := (others => '0');
    
    -- Error flip-flop component
    component err_register
        port (
            Error_in : in std_logic_vector(31 downto 0);
            Error_prev : out std_logic_vector(31 downto 0);
            trig : in std_logic
        );
    end component;

begin
    -- Instantiate error flip-flop
    ERR_REG : err_register
    port map (
        Error_in => error,
        Error_prev => prev_err_reg,
        trig => trigger
    );

    -- Main process for integration
    process(clock, reset)
    begin
        if reset = '1' then
            acc_total <= 0;
            curr_err <= 0;
            new_acc <= 0;
            err_delta <= 0;
            error_for_pid <= (others => '0');
        elsif rising_edge(clock) then
            -- Convert inputs to integer
            acc_total <= to_integer(signed(sum));
            curr_err <= to_integer(signed(error));
            prev_err <= to_integer(signed(prev_err_reg));

            if trigger = '1' then
                -- Integration calculation
                if integral_on = '1' then
                    new_acc <= acc_total + curr_err;
                else
                    new_acc <= 0;
                end if;
                
                -- Error difference calculation
                err_delta <= curr_err - prev_err;
                error_for_pid <= error;
            end if;
        end if;
    end process;

    -- Output process with saturation protection
    process(ki_denominator, ki_numerator, time_for_divider, prev_err_reg, trigger, sum, error, new_acc, err_delta)
    begin
        -- Apply saturation
        if new_acc < ((3072 * to_integer(unsigned(ki_denominator)) * 
                     to_integer(unsigned(time_for_divider))) / 
                     to_integer(unsigned(ki_numerator))) then
            new_sum <= std_logic_vector(to_signed(((3072 * to_integer(unsigned(ki_denominator)) * 
                     to_integer(unsigned(time_for_divider))) / 
                     to_integer(unsigned(ki_numerator))), 32));
        elsif new_acc > ((4000 * to_integer(unsigned(ki_denominator)) * 
                     to_integer(unsigned(time_for_divider))) / 
                     to_integer(unsigned(ki_numerator))) then
            new_sum <= std_logic_vector(to_signed(((4000 * to_integer(unsigned(ki_denominator)) * 
                     to_integer(unsigned(time_for_divider))) / 
                     to_integer(unsigned(ki_numerator))), 32));
        else
            new_sum <= std_logic_vector(to_signed(new_acc, 32));
        end if;

        -- Output error difference
        error_difference <= std_logic_vector(to_signed(err_delta, 32));
    end process;

end Behavioral;
