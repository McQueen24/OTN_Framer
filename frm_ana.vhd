library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use work.frm_test_util.all;

entity frm_ana is
  generic( TEST_NAME : string := "test" );
  
  port (
    clk         : in    std_logic;
    reset       : in    std_logic;
    in_data     : in    std_logic_vector(255 downto 0);
    test_conf   : in    test_config_type;
    otn_oh      : out   otn_overhead_type 
    );
end frm_ana;


architecture frm_ana_0 of frm_ana is

type      framer_state_types is (LOSS_OF_FRAME, IN_FRAME);  

signal    scr_pol          :  std_logic_vector(15 downto 0) := "0001000000001011";
signal    otn_framer_state :  framer_state_types;  

signal    in_data_1d       :  std_logic_vector(255 downto 0);
signal    in_data_256_s    :  std_logic_vector(255 downto 0);
signal    reset_int       :  std_logic;


begin

reset_int <= reset or test_conf.disable_ana;

process(clk, reset_int)

variable   txt             :  LINE;
variable   in_data_512     :  std_logic_vector(511 downto 0);
variable   in_data_256     :  std_logic_vector(255 downto 0);
variable   fas_pos         :  integer range 511 downto 256;
variable   pos             :  integer range 511 downto 256-128;
variable   otn_col         :  integer range 128 downto 0;
variable   otn_row         :  integer range 4 downto 0;
variable   mfas            :  std_logic_vector(7 downto 0);
variable   mfas_prev       :  std_logic_vector(7 downto 0);
variable   scr_reg         :  std_logic_vector(15 downto 0);
variable   frm_nr          :  std_logic_vector(31 downto 0);
variable   bip8_0          :  std_logic_vector(7 downto 0);
variable   bip8_1          :  std_logic_vector(7 downto 0);
variable   bip8_2          :  std_logic_vector(7 downto 0);
variable   JC1             :  std_logic_vector(7 downto 0);
variable   JC2             :  std_logic_vector(7 downto 0);
variable   JC3             :  std_logic_vector(7 downto 0);
variable   cbr_data_512    :  std_logic_vector(511 downto 0):= (others => '0');
variable   cbr_data_256    :  std_logic_vector(255 downto 0):= (others => '0');
variable   cbr_ptr         :  integer range 511 downto 0 := 0;
variable   cbr_en          :  std_logic;

variable   expected        :  unsigned(7 downto 0);
variable   expected256     :  std_logic_vector(255 downto 0);
variable   prbs_reg        :  std_logic_vector(30 downto 0);
variable   error_count     :  integer range 0 to 20000;

variable   ais             :  std_logic;
variable   oci             :  std_logic;
variable   lck             :  std_logic;


begin

  if (reset_int = '1') then

    otn_framer_state <= LOSS_OF_FRAME;
    in_data_1d <= (others => '0');
    in_data_512 := (others => '0');
    fas_pos := 511;
    frm_nr := (others => '0');
    bip8_2 := X"00";
    bip8_1 := X"00";
    bip8_0 := X"00";
    otn_oh.odu3ais <= X"00";  
    otn_oh.odu3oci <= X"00";  
    otn_oh.odu3lck <= X"00";  
  
  elsif clk'event and clk = '1' then
 

    case test_conf.conf is
    when "00" =>  --OTN mode

    
      in_data_1d <= in_data;    
      in_data_512 := in_data_1d & in_data;
      cbr_en := '0';   

      
      case otn_framer_state is
   
        when LOSS_OF_FRAME =>
   
            for n in 511 downto 256 loop
              if in_data_512(n downto n-8*6+1) = X"F6F6F6282828" then
                fas_pos := n;
                otn_col := 1;
                otn_row := 1;
                
                otn_scramble(fas_pos,test_conf.otn_scr_inh_ana,scr_reg,'1',in_data_512);
                
                bip8_2 := X"00";
                bip8_1 := X"00";
                bip8_0 := X"00";  
                otn_bip8(fas_pos,bip8_0,X"0003ffff",in_data_512);
                
                in_data_256_s <= in_data_512(fas_pos downto fas_pos-256+1);
                in_data_256 := in_data_512(fas_pos downto fas_pos-256+1);
                  
                mfas := in_data_512(fas_pos-8*6 downto fas_pos-8*7+1);
                otn_oh.MFAS <= mfas;
                otn_oh.SM_TTI(7+8*conv_integer(mfas(5 downto 0)) downto 8*conv_integer(mfas(5 downto 0))) <= in_data_512(fas_pos-8*7 downto fas_pos-8*8+1); 
                otn_oh.SM_BIP8 <= in_data_512(fas_pos-8*8 downto fas_pos-8*9+1) xor bip8_2;
                otn_oh.SM_AUX  <= in_data_512(fas_pos-8*9 downto fas_pos-8*10+1);
                otn_oh.GCC0 <= in_data_512(fas_pos-8*10 downto fas_pos-8*12+1);
                otn_oh.OTU3_RES <= in_data_512(fas_pos-8*12 downto fas_pos-8*14+1);
                otn_oh.OPU3_RES1 <= in_data_512(fas_pos-8*14 downto fas_pos-8*15+1);
                otn_oh.OPU3_JC1 <= in_data_512(fas_pos-8*15 downto fas_pos-8*16+1);
                JC1 := in_data_512(fas_pos-8*15 downto fas_pos-8*16+1);
                
                if test_conf.cbr_map = '1' then  --CBR demapping of payload                
                  cbr_ptr := 511;   
                  -- OH CBR        
                  cbr_data_512(cbr_ptr downto cbr_ptr-128+1) := in_data_256(127 downto 0);
                  cbr_ptr := cbr_ptr - 128;
                end if;
                
                otn_framer_state <= IN_FRAME;
                write(txt, string'("frm_ana: OTN_IN_FRAME"));
                writeline(output,txt);
                error_count := 0;
                exit;
              end if;
            end loop;  
    
       when IN_FRAME =>
  
          otn_col := otn_col + 1;
  
          case otn_row is
            when 1 => 
              
              if (otn_col = 1) then
                if (in_data_512(fas_pos downto fas_pos-8*6+1) /= X"F6F6F6282828") then
                  otn_framer_state <= LOSS_OF_FRAME; 
                  write(txt, string'("frm_ana: OTN_LOSS_OF_FRAME"));
                  writeline(output,txt);
  
                else
                  frm_nr := frm_nr + '1';
                  otn_scramble(fas_pos,test_conf.otn_scr_inh_ana,scr_reg,'1',in_data_512);
                                 
                  in_data_256_s <= in_data_512(fas_pos downto fas_pos-256+1);
                  in_data_256 := in_data_512(fas_pos downto fas_pos-256+1);
                  
                  mfas_prev := mfas;
                  mfas := in_data_512(fas_pos-8*6 downto fas_pos-8*7+1);
                  
                  if (mfas_prev + '1' /= mfas) then
                    write(txt, string'("frm_ana: WRONG mfas"));
                    writeline(output,txt);
                  end if;
                  
                  bip8_2 := bip8_1;
                  bip8_1 := bip8_0;
                  bip8_0 := X"00";                
                  
                  otn_oh.MFAS <= mfas;
                  otn_oh.SM_TTI(7+8*conv_integer(mfas(5 downto 0)) downto 8*conv_integer(mfas(5 downto 0))) <= in_data_512(fas_pos-8*7 downto fas_pos-8*8+1); 
                  otn_oh.SM_BIP8 <= in_data_512(fas_pos-8*8 downto fas_pos-8*9+1) xor bip8_2;
                  otn_oh.SM_AUX  <= in_data_512(fas_pos-8*9 downto fas_pos-8*10+1);
                  otn_oh.GCC0 <= in_data_512(fas_pos-8*10 downto fas_pos-8*12+1);
                  otn_oh.OTU3_RES <= in_data_512(fas_pos-8*12 downto fas_pos-8*14+1);
                  otn_oh.OPU3_RES1 <= in_data_512(fas_pos-8*14 downto fas_pos-8*15+1);
                  otn_oh.OPU3_JC1 <= in_data_512(fas_pos-8*15 downto fas_pos-8*16+1);
                  JC1 := in_data_512(fas_pos-8*15 downto fas_pos-8*16+1);
                end if;
              else
                otn_scramble(fas_pos,test_conf.otn_scr_inh_ana,scr_reg,'0',in_data_512); 
                in_data_256_s <= in_data_512(fas_pos downto fas_pos-256+1);
                in_data_256 := in_data_512(fas_pos downto fas_pos-256+1);
                
              end if;
              
              
              if (otn_col = 1) then
                ais := '1';
                oci := '1';
                lck := '1';
                otn_bip8(fas_pos,bip8_0,X"0003ffff",in_data_512);            
                --odu_ais(fas_pos,'1',X"0003ffff",in_data_512,ais,oci,lck);            
              elsif (otn_col < 120) then
                otn_bip8(fas_pos,bip8_0,X"ffffffff",in_data_512);
                odu_ais(fas_pos,'1',X"ffffffff",in_data_512,ais,oci,lck);            
              elsif (otn_col = 120) then
                otn_bip8(fas_pos,bip8_0,X"ffff0000",in_data_512);
                odu_ais(fas_pos,'1',X"ffff0000",in_data_512,ais,oci,lck);            
              end if;  
                         
                 
              if test_conf.cbr_map = '1' and (otn_col <= 120) then  --CBR demapping of payload                
              
                if (otn_col = 1) then   -- OH CBR

                  cbr_data_512(cbr_ptr downto cbr_ptr-128+1) := in_data_256(127 downto 0);
                  cbr_ptr := cbr_ptr - 128;
                  
                  --if (in_data_256(127 downto 0) = ";

                elsif (otn_col = 40) or (otn_col = 80) then -- CBR 16FS
                  
                  assert (in_data_256(127 downto 0) = X"ffffffffffffffffffffffffffffffff") report "16FS expected";
                  
                  cbr_data_512(cbr_ptr downto cbr_ptr-128+1) := in_data_256(255 downto 128);
                  cbr_ptr := cbr_ptr - 128;

                elsif (otn_col < 120) then  -- CBR CBR
  
                  cbr_data_512(cbr_ptr downto cbr_ptr-256+1) := in_data_256(255 downto 0);
                  cbr_ptr := cbr_ptr - 256;
  
                elsif (otn_col = 120) then  -- CBR FEC

                  cbr_data_512(cbr_ptr downto cbr_ptr-128+1) := in_data_256(255 downto 128);
                  cbr_ptr := cbr_ptr - 128;
  
                end if;
                
                if (cbr_ptr < 256) then
                  
                  cbr_en := '1';
                  cbr_ptr := cbr_ptr + 256; 
                  
                  cbr_data_256 := cbr_data_512(511 downto 256);
                  cbr_data_512(511 downto 256) := cbr_data_512(255 downto 0);
                end if;
                
              end if;  -- CBR demapping
                 
                 
              if (otn_col = 127) then
                otn_col := 0;
                otn_row := otn_row + 1;
              end if;
              
            when 2 => 
              
              otn_scramble(fas_pos,test_conf.otn_scr_inh_ana,scr_reg,'0',in_data_512); 
              in_data_256_s <= in_data_512(fas_pos downto fas_pos-256+1);       
              in_data_256 := in_data_512(fas_pos downto fas_pos-256+1);       
              if (otn_col = 1) then
                pos := fas_pos-128;
                otn_oh.ODU3_RES1 <= in_data_512(pos-8*0 downto pos-8*3+1);
                otn_oh.TCM_ACT <= in_data_512(pos-8*3 downto pos-8*4+1);
  
                otn_oh.TCM6_TTI(7+8*conv_integer(mfas(5 downto 0)) downto 8*conv_integer(mfas(5 downto 0))) <= in_data_512(pos-8*4 downto pos-8*5+1);
                otn_oh.TCM6_BIP8 <= in_data_512(pos-8*5 downto pos-8*6+1) xor bip8_2;
                otn_oh.TCM6_AUX <= in_data_512(pos-8*6 downto pos-8*7+1);
                
                otn_oh.TCM5_TTI(7+8*conv_integer(mfas(5 downto 0)) downto 8*conv_integer(mfas(5 downto 0))) <= in_data_512(pos-8*7 downto pos-8*8+1);
                otn_oh.TCM5_BIP8 <= in_data_512(pos-8*8 downto pos-8*9+1) xor bip8_2;
                otn_oh.TCM5_AUX <= in_data_512(pos-8*9 downto pos-8*10+1);
                
                otn_oh.TCM4_TTI(7+8*conv_integer(mfas(5 downto 0)) downto 8*conv_integer(mfas(5 downto 0))) <= in_data_512(pos-8*10 downto pos-8*11+1);
                otn_oh.TCM4_BIP8 <= in_data_512(pos-8*11 downto pos-8*12+1) xor bip8_2;
                otn_oh.TCM4_AUX <= in_data_512(pos-8*12 downto pos-8*13+1);
                
                otn_oh.FTFL <= in_data_512(pos-8*13 downto pos-8*14+1);
  
                otn_oh.OPU3_RES2 <= in_data_512(pos-8*14 downto pos-8*15+1);
                otn_oh.OPU3_JC2 <= in_data_512(pos-8*15 downto pos-8*16+1);
                JC2 := in_data_512(pos-8*15 downto pos-8*16+1);
                
                if in_data_512(pos-8*6-5 downto pos-8*7+1) /= "111" or
                   in_data_512(pos-8*9-5 downto pos-8*10+1) /= "111" or
                   in_data_512(pos-8*12-5 downto pos-8*13+1) /= "111" then
                  ais := '0';
                end if;
                
                if in_data_512(pos-8*6-5 downto pos-8*7+1) /= "110" or
                   in_data_512(pos-8*9-5 downto pos-8*10+1) /= "110" or
                   in_data_512(pos-8*12-5 downto pos-8*13+1) /= "110" then
                  oci := '0';
                end if;
  
                if in_data_512(pos-8*6-5 downto pos-8*7+1) /= "101" or
                   in_data_512(pos-8*9-5 downto pos-8*10+1) /= "101" or
                   in_data_512(pos-8*12-5 downto pos-8*13+1) /= "101" then
                  lck := '0';
                end if;
  
              end if;  
              
              
              if (otn_col = 1) then
                otn_bip8(fas_pos,bip8_0,X"00000003",in_data_512);            
                --odu_ais(fas_pos,'1',X"00000003",in_data_512,ais,oci,lck);            
              elsif (otn_col < 120) then
                otn_bip8(fas_pos,bip8_0,X"ffffffff",in_data_512);
                odu_ais(fas_pos,'1',X"ffffffff",in_data_512,ais,oci,lck);            
              elsif (otn_col = 120) then
                otn_bip8(fas_pos,bip8_0,X"ffffffff",in_data_512);
                odu_ais(fas_pos,'1',X"ffffffff",in_data_512,ais,oci,lck);            
              end if;             
                
              if test_conf.cbr_map = '1' and (otn_col <= 120) then  --CBR demapping of payload                
  
                if (otn_col = 1) then   -- FEC OH  
                
                  --(nothing to demap)

                elsif (otn_col = 41) or (otn_col = 81) then -- 16FS CBR
                  
                  assert (in_data_256(255 downto 128) = X"ffffffffffffffffffffffffffffffff") report "16FS expected";
                  
                  cbr_data_512(cbr_ptr downto cbr_ptr-128+1) := in_data_256(127 downto 0);
                  cbr_ptr := cbr_ptr - 128;

                elsif (otn_col < 120) then  -- CBR CBR
  
                  cbr_data_512(cbr_ptr downto cbr_ptr-256+1) := in_data_256(255 downto 0);
                  cbr_ptr := cbr_ptr - 256;
  
                elsif (otn_col = 120) then  -- CBR CBR

                  cbr_data_512(cbr_ptr downto cbr_ptr-256+1) := in_data_256(255 downto 0);
                  cbr_ptr := cbr_ptr - 256;
  
                end if;
                
                if (cbr_ptr < 256) then
                  
                  cbr_en := '1';
                  cbr_ptr := cbr_ptr + 256; 
                  
                  cbr_data_256 := cbr_data_512(511 downto 256);
                  cbr_data_512(511 downto 256) := cbr_data_512(255 downto 0);
                end if;
                
              end if;  -- CBR demapping
                
              if (otn_col = 128) then
                otn_col := 0;
                otn_row := otn_row + 1;
              end if;     
               
            when 3 =>
              
             otn_scramble(fas_pos,test_conf.otn_scr_inh_ana,scr_reg,'0',in_data_512);
             in_data_256_s <= in_data_512(fas_pos downto fas_pos-256+1);        
             in_data_256 := in_data_512(fas_pos downto fas_pos-256+1);        
             if (otn_col = 1) then
                 pos := fas_pos;
     
                 otn_oh.TCM3_TTI(7+8*conv_integer(mfas(5 downto 0)) downto 8*conv_integer(mfas(5 downto 0))) <= in_data_512(pos-8*0 downto pos-8*1+1);
                 otn_oh.TCM3_BIP8 <= in_data_512(pos-8*1 downto pos-8*2+1) xor bip8_2;
                 otn_oh.TCM3_AUX <= in_data_512(pos-8*2 downto pos-8*3+1);
                 
                 otn_oh.TCM2_TTI(7+8*conv_integer(mfas(5 downto 0)) downto 8*conv_integer(mfas(5 downto 0))) <= in_data_512(pos-8*3 downto pos-8*4+1);
                 otn_oh.TCM2_BIP8 <= in_data_512(pos-8*4 downto pos-8*5+1) xor bip8_2;
                 otn_oh.TCM2_AUX <= in_data_512(pos-8*5 downto pos-8*6+1);
  
                 otn_oh.TCM1_TTI(7+8*conv_integer(mfas(5 downto 0)) downto 8*conv_integer(mfas(5 downto 0))) <= in_data_512(pos-8*6 downto pos-8*7+1);
                 otn_oh.TCM1_BIP8 <= in_data_512(pos-8*7 downto pos-8*8+1) xor bip8_2;
                 otn_oh.TCM1_AUX <= in_data_512(pos-8*8 downto pos-8*9+1);
                  
                 otn_oh.PM_TTI(7+8*conv_integer(mfas(5 downto 0)) downto 8*conv_integer(mfas(5 downto 0))) <= in_data_512(pos-8*9 downto pos-8*10+1);
                 otn_oh.PM_BIP8 <= in_data_512(pos-8*10 downto pos-8*11+1) xor bip8_2;
                 otn_oh.PM_AUX <= in_data_512(pos-8*11 downto pos-8*12+1);
                 
                 otn_oh.EXP <= in_data_512(pos-8*12 downto pos-8*14+1);
  
                 otn_oh.OPU3_RES3 <= in_data_512(pos-8*14 downto pos-8*15+1);
                 otn_oh.OPU3_JC3 <= in_data_512(pos-8*15 downto pos-8*16+1);
                 JC3 := in_data_512(pos-8*15 downto pos-8*16+1);
                 
                 if in_data_512(pos-8*2-5 downto pos-8*3+1) /= "111" or
                    in_data_512(pos-8*5-5 downto pos-8*6+1) /= "111" or
                    in_data_512(pos-8*8-5 downto pos-8*9+1) /= "111" then
                 
                   ais := '0';
                 end if;
                 
                 if in_data_512(pos-8*2-5 downto pos-8*3+1) /= "110" or
                    in_data_512(pos-8*5-5 downto pos-8*6+1) /= "110" or
                    in_data_512(pos-8*8-5 downto pos-8*9+1) /= "110" then
                 
                   oci := '0';
                 end if;

                 if in_data_512(pos-8*2-5 downto pos-8*3+1) /= "101" or
                    in_data_512(pos-8*5-5 downto pos-8*6+1) /= "101" or
                    in_data_512(pos-8*8-5 downto pos-8*9+1) /= "101" then
                 
                   lck := '0';
                 end if;
                 
                 
              end if;
  
              if (otn_col = 1) then
                otn_bip8(fas_pos,bip8_0,X"0003ffff",in_data_512);            
                --odu_ais(fas_pos,'1',X"0003ffff",in_data_512,ais,oci,lck);            
              elsif (otn_col < 120) then
                otn_bip8(fas_pos,bip8_0,X"ffffffff",in_data_512);
                odu_ais(fas_pos,'1',X"ffffffff",in_data_512,ais,oci,lck);            
              elsif (otn_col = 120) then
                otn_bip8(fas_pos,bip8_0,X"ffff0000",in_data_512);
                odu_ais(fas_pos,'1',X"ffff0000",in_data_512,ais,oci,lck);            
              end if;             

              if test_conf.cbr_map = '1' and (otn_col <= 120) then  --CBR demapping of payload                

                if (otn_col = 1) then   -- OH CBR

                  cbr_data_512(cbr_ptr downto cbr_ptr-128+1) := in_data_256(127 downto 0);
                  cbr_ptr := cbr_ptr - 128;

                elsif (otn_col = 40) or (otn_col = 80) then -- CBR 16FS
                  
                  assert (in_data_256(127 downto 0) = X"ffffffffffffffffffffffffffffffff") report "16FS expected";
                  
                  cbr_data_512(cbr_ptr downto cbr_ptr-128+1) := in_data_256(255 downto 128);
                  cbr_ptr := cbr_ptr - 128;

                elsif (otn_col < 120) then  -- CBR CBR
  
                  cbr_data_512(cbr_ptr downto cbr_ptr-256+1) := in_data_256(255 downto 0);
                  cbr_ptr := cbr_ptr - 256;
  
                elsif (otn_col = 120) then  -- CBR FEC

                  cbr_data_512(cbr_ptr downto cbr_ptr-128+1) := in_data_256(255 downto 128);
                  cbr_ptr := cbr_ptr - 128;
  
                end if;
                
                if (cbr_ptr < 256) then
                  
                  cbr_en := '1';
                  cbr_ptr := cbr_ptr + 256; 
                  
                  cbr_data_256 := cbr_data_512(511 downto 256);
                  cbr_data_512(511 downto 256) := cbr_data_512(255 downto 0);
                end if;
                
              end if;  -- CBR demapping
        
              if (otn_col = 127) then
                otn_col := 0;
                otn_row := otn_row + 1;
              end if;  
                  
            when 4 => 
  
              otn_scramble(fas_pos,test_conf.otn_scr_inh_ana,scr_reg,'0',in_data_512);
              in_data_256_s <= in_data_512(fas_pos downto fas_pos-256+1);
              in_data_256 := in_data_512(fas_pos downto fas_pos-256+1);
                                
              if (otn_col = 1) then
                pos := fas_pos-128;
                
                otn_oh.GCC1 <= in_data_512(pos-8*0 downto pos-8*2+1);
                otn_oh.GCC2 <= in_data_512(pos-8*2 downto pos-8*4+1);
                
                otn_oh.APS <= in_data_512(pos-8*4 downto pos-8*8+1);
                otn_oh.ODU3_RES2 <= in_data_512(pos-8*8 downto pos-8*14+1);
                
                
                --husk: TODO full PT support
                if (mfas = X"00") then
                  otn_oh.PT <= in_data_512(pos-8*14 downto pos-8*15+1);
                elsif (mfas = X"01") then
                  otn_oh.vcPT <= in_data_512(pos-8*14 downto pos-8*15+1);
                elsif (in_data_512(pos-8*14 downto pos-8*15+1) /= X"00") then
                  assert false report "PSI RES field not zero";
                end if;
              end if;
  
  
              if (otn_col = 1) then
                otn_bip8(fas_pos,bip8_0,X"00000003",in_data_512);            
                --odu_ais(fas_pos,'1',X"00000003",in_data_512,ais,oci,lck);            
              elsif (otn_col < 120) then
                otn_bip8(fas_pos,bip8_0,X"ffffffff",in_data_512);
                odu_ais(fas_pos,'1',X"ffffffff",in_data_512,ais,oci,lck);            
              elsif (otn_col = 120) then
                otn_bip8(fas_pos,bip8_0,X"ffffffff",in_data_512);
                odu_ais(fas_pos,'1',X"ffffffff",in_data_512,ais,oci,lck);            
                
                otn_oh.odu3ais(0) <= ais;
                otn_oh.odu3oci(0) <= oci;
                otn_oh.odu3lck(0) <= lck;
              end if;             
  
  
              if test_conf.cbr_map = '1' and (otn_col <= 120) then  --CBR demapping of payload                
  
                if (otn_col = 1) then   -- FEC OH(NJ0)  
                  
                  if JC1(1 downto 0) = "00" and JC2(1 downto 0) = "00" and JC3(1 downto 0) = "00" then
                    -- No justification. (no CBR mapping)
                    assert (in_data_256(7 downto 0) = X"00") report "NJO not Zero"; 
                      
                  elsif JC1(1 downto 0) = "01" and JC2(1 downto 0) = "01" and JC3(1 downto 0) = "01" then
                  
                    --Include NJO in demapping
                    cbr_data_512(cbr_ptr downto cbr_ptr-8+1) := in_data_256(7 downto 0);
                    cbr_ptr := cbr_ptr - 8;
                    
                  elsif JC1(1 downto 0) = "11" and JC2(1 downto 0) = "11" and JC3(1 downto 0) = "11" then
                    
                    -- Exclude NJO & PJO in demapping.
                    assert (in_data_256(7 downto 0) = X"00") report "NJO not Zero";
                    
                  else 
                    assert false report "Invalid combination of JC bytes";
                  end if;
                  
                elsif (otn_col = 2) and JC1(1 downto 0) = "11" and JC2(1 downto 0) = "11" and JC3(1 downto 0) = "11" then -- (PJO)CBR  CBR
                
                  assert (in_data_256(255 downto 255-8+1) = X"00") report "PJO not Zero";
                  
                  cbr_data_512(cbr_ptr downto cbr_ptr-256+1+8) := in_data_256(255-8 downto 0);
                  cbr_ptr := cbr_ptr - 256 + 8;                      

                elsif (otn_col = 41) or (otn_col = 81) then -- 16FS CBR
                  
                  assert (in_data_256(255 downto 128) = X"ffffffffffffffffffffffffffffffff") report "16FS expected";
                  
                  cbr_data_512(cbr_ptr downto cbr_ptr-128+1) := in_data_256(127 downto 0);
                  cbr_ptr := cbr_ptr - 128;

                elsif (otn_col < 120) then  -- CBR CBR
  
                  cbr_data_512(cbr_ptr downto cbr_ptr-256+1) := in_data_256(255 downto 0);
                  cbr_ptr := cbr_ptr - 256;
  
                elsif (otn_col = 120) then  -- CBR CBR

                  cbr_data_512(cbr_ptr downto cbr_ptr-256+1) := in_data_256(255 downto 0);
                  cbr_ptr := cbr_ptr - 256;
  
                end if;
                
                if (cbr_ptr < 256) then
                  
                  cbr_en := '1';
                  cbr_ptr := cbr_ptr + 256; 
                  
                  cbr_data_256 := cbr_data_512(511 downto 256);
                  cbr_data_512(511 downto 256) := cbr_data_512(255 downto 0);
                end if;
                
              end if;  -- CBR demapping

   
              if (otn_col = 128) then
                otn_col := 0;
                otn_row := (otn_row + 1) mod 4;
                if (error_count > 0) then
                  write(txt, string'("frm_ana: Bad OTN Frame. Errors in frame  "));
                  write(txt, integer'(error_count));
                  writeline(output,txt);
                  error_count := 0;
                end if;               
              end if;
              
          when others => assert false report "Invalid state";   
       end case;  --OTN row

       if false then
       else
         
         if (test_conf.prbs = '0') and (cbr_en = '1') then -- CBR demap counter
           
           otn_oh.demap <= X"00";
           for n in 31 downto 0 loop
             if unsigned(cbr_data_256(7+n*8 downto n*8)) /= expected then
               otn_oh.demap <= X"01";
               error_count := error_count + 1;
             end if;
             expected := unsigned(cbr_data_256(7+n*8 downto n*8)) + "1";
           end loop;
    
         end if;
       
         if (test_conf.prbs = '1') and (cbr_en = '1') then -- CBR demap PRBS
           
           otn_oh.demap <= X"00";
    
           --assert (cbr_data_256 = expected256) report "cbr_data_256 >< expected256";
    
           if cbr_data_256 /= expected256 then
             otn_oh.demap <= X"01";
             prbs_reg(30 downto 0) := cbr_data_256(255 downto 255-30);
             prbs31(prbs_reg,X"ffffffff",expected256);
             error_count := error_count + 1;
           end if;
           
           prbs31(prbs_reg,X"ffffffff",expected256);
             
         end if;
       end if; --test_conf.stm

              
     end case;  --Frame mode
   
     otn_oh.row <= otn_row;
     otn_oh.col <= otn_col;
     otn_oh.frm_nr <= frm_nr;
     otn_oh.data <= in_data_512(fas_pos downto fas_pos-256+1);      
  

   when "01" => -- CBR mapping mode
     
     if false then
     else 
       case test_conf.prbs is
       when '0' =>  -- CBR Mapping mode counter
       
         otn_oh.demap <= X"00";
         for n in 31 downto 0 loop
           if unsigned(in_data(7+n*8 downto n*8)) /= expected then
             otn_oh.demap <= X"01";
           end if;
           expected := unsigned(in_data(7+n*8 downto n*8)) + "1";
         end loop;
     
       when '1' => -- CBR mapping mode PRBS
       
         otn_oh.demap <= X"00";
        
         if in_data /= expected256 then
           otn_oh.demap <= X"01";
           prbs_reg(30 downto 0) := in_data(255 downto 255-30);
           prbs31(prbs_reg,X"ffffffff",expected256);
         end if;
         
         prbs31(prbs_reg,X"ffffffff",expected256);       
      
       when others => 
       end case;  --prbs  
     end if; --test_conf.stm 
     
   when others => assert false report "Invalid configuration";
      
   end case; -- Conf 
 end if;
 
 end process; 
 
  
end frm_ana_0;

