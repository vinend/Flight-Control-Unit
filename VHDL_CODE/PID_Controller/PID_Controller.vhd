library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use UNISIM.VComponents.all;

entity PID_Controller is
	generic (
		data_width : integer := 32;
		internal_width : integer := 16;
	);

	port (
		clock : in std_logic;
		reset : in std_logic;

		kp : in std_logic_vector(internal_width-1 downto 0);
		ki : in std_logic_vector(internal_width-1 downto 0);
		kd : in std_logic_vector(internal_width-1 downto 0);

		setpoint : in std_logic_vector(data_width-1 downto 0);
		setpoint_actual : in std_logic_vector(data_width-1 downto 0);
		data_output	: out std_logic_vector(data_width-1 downto 0)
	);

end PID_Controller;

architecture Behavioral of PID_Controller is



end Behavioral;