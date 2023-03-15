
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

entity frm_demap is
port (
	rst	: in std_logic;
	clk	: in std_logic;
	in_dat	: in std_logic_vector(255 downto 0);
	in_val	: in std_logic;
	out_dat	: out std_logic_vector(255 downto 0)
	);
end entity;


architecture frm_demap_arch of frm_demap is


begin



end architecture;