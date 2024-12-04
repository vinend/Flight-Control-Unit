Library IEEE;
Use IEEE.STD_LOGIC_1164.All;
Use IEEE.NUMERIC_STD.All;

Entity PWM_Generator Is
    Generic (
        clock_freq : Integer := 100000000;
        pwm_freq  : Integer := 25000
    );
    Port (
        enable     : In std_logic;
        duty_in    : In STD_LOGIC_VECTOR (11 Downto 0);
        clock     : In STD_LOGIC;
        pwm_out   : Out STD_LOGIC
    );
End PWM_Generator;

Architecture Behavioral Of PWM_Generator Is
    Constant pwm_period      : Integer := clock_freq/pwm_freq;
    Signal count            : Integer := 0;
    Signal enable_reg       : std_logic := '0';
    Signal duty_reg        : unsigned(11 Downto 0) := "000000000000";
    signal idle_duty       : integer := 3072;
Begin
    Process (clock, duty_in, count, enable, idle_duty, duty_reg)
    Begin
        If clock'EVENT And clock = '1' Then
            If (count < 4000) Then    -- 400us period limit
                count <= count + 2;
            Else
                count <= 0;
            End If;
        End If;

        If count <= duty_reg Then     -- PWM generation based on duty cycle
            pwm_out <= '1';
        Else
            pwm_out <= '0';
        End If;

        If enable = '1' Then          -- Duty cycle control
            duty_reg <= unsigned(duty_in);
        Else
            duty_reg <= to_unsigned(idle_duty, 12);
        End If;
    End Process;
End Behavioral;