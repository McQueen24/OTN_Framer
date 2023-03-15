library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use work.frm_test_util.all;

entity frm_gen is
  generic( TEST_NAME : string := "test" );
  
  port (
    clk         : in    std_logic;
    reset       : in    std_logic;
    out_data    : out   std_logic_vector(255 downto 0);
    stat        : out   gen_stat_type;
    test_conf   : in    test_config_type; 
    otn_oh      : in    otn_overhead_type
    );
end frm_gen;


architecture frm_gen_0 of frm_gen is

signal     reset_int       :  std_logic;


begin
   
reset_int <= reset or test_conf.disable_gen;   
   
      
process(clk, reset_int)
  
variable   otn_col         :  integer range 128 downto 0;
variable   otn_row         :  integer range 4 downto 0;
variable   data_512        :  std_logic_vector(511 downto 0);
variable   tti_index       :  integer range 63 downto 0;
variable   mfas            :  std_logic_vector(7 downto 0);
variable   fas_pos         :  integer range 511 downto 256;
variable   pos             :  integer range 511 downto 256-128;
variable   scr_reg         :  std_logic_vector(15 downto 0);
variable   bip8_0          :  std_logic_vector(7 downto 0);
variable   bip8_1          :  std_logic_vector(7 downto 0);
variable   bip8_2          :  std_logic_vector(7 downto 0);
variable   frm_nr          :  std_logic_vector(31 downto 0);
variable   cnt             :  integer;
variable   prbs_reg        :  std_logic_vector(30 downto 0);
variable   iout_data       :  std_logic_vector(255 downto 0);
variable   jc_index        :  integer range 15 downto 0;

variable   cbr_data_512    :  std_logic_vector(511 downto 0):= (others => '0');
variable   cbr_data_256    :  std_logic_vector(255 downto 0):= (others => '0');
variable   cbr_ptr         :  integer range 511 downto 0 := 0;
variable   cbr_en          :  std_logic;
variable   prbs11_reg      :  std_logic_vector(10 downto 0);
variable   prbs31_reg      :  std_logic_vector(30 downto 0);
variable   prbs7_reg       :  std_logic_vector(6 downto 0);
variable   prbs23_reg      :  std_logic_vector(22 downto 0);
  
  begin
    if (reset_int = '1' ) then

      otn_col := 0;
      otn_row := 1;
      data_512 := (others => '0'); 
      mfas := X"02";
      out_data(255 downto 128) <= (others => '1');
      out_data(127 downto 0) <= (others => '0');
      bip8_2 := X"00";
      bip8_1 := X"00";
      bip8_0 := X"00"; 
      frm_nr := (others => '0'); 
      cnt := 0;    
      stat.frm_nr <= (others => '0');
      stat.MFAS <= (others => '0');   
      prbs_reg := (others => '1');   
      jc_index := 15;
      cbr_ptr := 511;
      cbr_en := '1';
           
    elsif clk'event and clk = '1' then

      data_512(otn_oh.fas_pos downto otn_oh.fas_pos-256+1) := (others => '0'); 

      case test_conf.conf is
      when "00" =>  --OTN mode

        if false then
          --data_512(otn_oh.fas_pos downto otn_oh.fas_pos-8*32+1) := loop_ana.data;
          --otn_col := loop_ana.col;
          --otn_row := loop_ana.row;
        else
          otn_col := otn_col + 1;
          for i in 0 to 31 loop
            data_512(otn_oh.fas_pos-8*i downto otn_oh.fas_pos-8*(i+1)+1) := conv_std_logic_vector(i*4,8) xor mfas;
          end loop;
          
          if (cbr_en = '1') then
         
            if false then
              
            else
            
              case test_conf.prbs is
              when '0' =>  -- CBR Mapping mode counter
               
                for n in 31 downto 0 loop
                  cbr_data_256(7+n*8 downto n*8) := conv_std_logic_vector(cnt,8);
                  cnt := cnt + 1;
                end loop;
                    
              when '1' =>  -- CBR Mapping mode PRBS
      
                prbs31(prbs_reg,X"ffffffff",cbr_data_256);      
              
              when others => 
              end case;  --prbs
            end if;
             
            cbr_en := '0';
          end if; -- cbr_en
            
        end if; --loopb
        
   
        case otn_row is
          when 1 => 
            
            if (otn_col = 1) then 
              
              fas_pos := otn_oh.fas_pos;
              
              tti_index := conv_integer(mfas(5 downto 0));
  
              bip8_2 := bip8_1;
              bip8_1 := bip8_0;
              bip8_0 := X"00";                
  
              data_512(fas_pos downto fas_pos-8*6+1) := otn_oh.FAS;
              data_512(fas_pos-8*6 downto fas_pos-8*7+1) := mfas xor otn_oh.MFAS;
              
              stat.frm_nr <= frm_nr;
              stat.MFAS <= mfas;
                
              frm_nr := frm_nr + '1';

          
              data_512(fas_pos-8*7 downto fas_pos-8*8+1) := otn_oh.SM_TTI(7+8*tti_index downto 8*tti_index);
              data_512(fas_pos-8*8 downto fas_pos-8*9+1) := bip8_2 xor otn_oh.SM_BIP8;
              data_512(fas_pos-8*9 downto fas_pos-8*10+1) := otn_oh.SM_AUX;
              
              data_512(fas_pos-8*10 downto fas_pos-8*12+1) := otn_oh.GCC0;
              data_512(fas_pos-8*12 downto fas_pos-8*14+1) := otn_oh.OTU3_RES;
              data_512(fas_pos-8*14 downto fas_pos-8*15+1) := otn_oh.OPU3_RES1;
              data_512(fas_pos-8*15 downto fas_pos-8*16+1) := otn_oh.OPU3_JC1 xor ("000000" & otn_oh.jc_seq(2*jc_index+1 downto 2*jc_index));           
              
            end if;
            
            
            if test_conf.cbr_map = '1'  and (otn_col <= 120) then  --CBR mapping of payload                
                
              if (otn_col = 1) then   -- OH CBR

                data_512(fas_pos-128 downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-128+1);
                cbr_ptr := cbr_ptr - 128;                
                
              elsif (otn_col = 40) or (otn_col = 80) then -- CBR 16FS
                
                
                data_512(fas_pos downto fas_pos-128+1) := cbr_data_512(cbr_ptr downto cbr_ptr-128+1);
                data_512(fas_pos-128 downto fas_pos-256+1) := X"ffffffffffffffffffffffffffffffff"; -- 16FS
                cbr_ptr := cbr_ptr - 128;
                
              elsif (otn_col < 120) then  -- CBR CBR

                data_512(fas_pos downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-256+1);
                cbr_ptr := cbr_ptr - 256;

              elsif (otn_col = 120) then  -- CBR FEC

                data_512(fas_pos downto fas_pos-128+1) := cbr_data_512(cbr_ptr downto cbr_ptr-128+1);
                cbr_ptr := cbr_ptr - 128;
                
              end if;
              
              if (cbr_ptr < 256) then
                
                cbr_en := '1';

                cbr_ptr := cbr_ptr + 256; 
                
                cbr_data_512(511 downto 256) := cbr_data_512(255 downto 0);
                cbr_data_512(255 downto 0) := cbr_data_256;
              end if;
              
            end if;  -- CBR demapping            
    
            if (otn_col = 1) then 
          
              otn_bip8(fas_pos,bip8_0,X"0003ffff",data_512);
              otn_scramble(fas_pos,test_conf.otn_scr_inh_gen,scr_reg,'1',data_512);

            else
  
              if (otn_col < 120) then
                otn_bip8(fas_pos,bip8_0,X"ffffffff",data_512);
              elsif (otn_col = 120) then
                otn_bip8(fas_pos,bip8_0,X"ffff0000",data_512);
              end if;             
              
              otn_scramble(fas_pos,test_conf.otn_scr_inh_gen,scr_reg,'0',data_512); 
            end if;
            
            
            if (otn_col = 127) then
              otn_col := 0;
              otn_row := otn_row + 1;
            end if;
              
          when 2 =>
            
            if (otn_col = 1) then
              pos := fas_pos-128;
              
              data_512(pos-8*0 downto pos-8*3+1) := otn_oh.ODU3_RES1;
              data_512(pos-8*3 downto pos-8*4+1) := otn_oh.TCM_ACT;
              
              data_512(pos-8*4 downto pos-8*5+1) := otn_oh.TCM6_TTI(7+8*tti_index downto 8*tti_index);
              data_512(pos-8*5 downto pos-8*6+1) := bip8_2 xor otn_oh.TCM6_BIP8;
              data_512(pos-8*6 downto pos-8*7+1) := otn_oh.TCM6_AUX;
              
              data_512(pos-8*7 downto pos-8*8+1) := otn_oh.TCM5_TTI(7+8*tti_index downto 8*tti_index);
              data_512(pos-8*8 downto pos-8*9+1) := bip8_2 xor otn_oh.TCM5_BIP8;
              data_512(pos-8*9 downto pos-8*10+1) := otn_oh.TCM5_AUX;
              
              data_512(pos-8*10 downto pos-8*11+1) := otn_oh.TCM4_TTI(7+8*tti_index downto 8*tti_index);
              data_512(pos-8*11 downto pos-8*12+1) := bip8_2 xor otn_oh.TCM4_BIP8; 
              data_512(pos-8*12 downto pos-8*13+1) := otn_oh.TCM4_AUX;  
              
              data_512(pos-8*13 downto pos-8*14+1) := otn_oh.FTFL;     
              
              data_512(pos-8*14 downto pos-8*15+1) := otn_oh.OPU3_RES2;
              data_512(pos-8*15 downto pos-8*16+1) := otn_oh.OPU3_JC2 xor ("000000" & otn_oh.jc_seq(2*jc_index+1 downto 2*jc_index));

            end if;  
  
  
            if test_conf.cbr_map = '1' and (otn_col <= 120) then  --CBR mapping of payload                

              if (otn_col = 1) then   -- FEC OH  
              
                --(nothing to map)

              elsif (otn_col = 41) or (otn_col = 81) then -- 16FS CBR
                
                data_512(fas_pos downto fas_pos-128+1) := X"ffffffffffffffffffffffffffffffff"; -- 16FS
                data_512(fas_pos-128 downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-128+1);
                cbr_ptr := cbr_ptr - 128;

              elsif (otn_col < 120) then  -- CBR CBR

                data_512(fas_pos downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-256+1);
                cbr_ptr := cbr_ptr - 256;

              elsif (otn_col = 120) then  -- CBR CBR

                data_512(fas_pos downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-256+1);
                cbr_ptr := cbr_ptr - 256;

              end if;
              
              if (cbr_ptr < 256) then
                
                cbr_en := '1';

                cbr_ptr := cbr_ptr + 256; 
                
                cbr_data_512(511 downto 256) := cbr_data_512(255 downto 0);
                cbr_data_512(255 downto 0) := cbr_data_256;

              end if;
              
            end if;  -- CBR demapping
            
            
            if (otn_col = 1) then
              otn_bip8(fas_pos,bip8_0,X"00000003",data_512);            
            elsif (otn_col < 120) then
              otn_bip8(fas_pos,bip8_0,X"ffffffff",data_512);
            elsif (otn_col = 120) then
              otn_bip8(fas_pos,bip8_0,X"ffffffff",data_512);
            end if;                         
              
              
            otn_scramble(fas_pos,test_conf.otn_scr_inh_gen,scr_reg,'0',data_512);  
              
            if (otn_col = 128) then
              otn_col := 0;
              otn_row := otn_row + 1;
            end if;     
            
          when 3 =>
  
            if (otn_col = 1) then
              pos := fas_pos;
              
              data_512(pos-8*0 downto pos-8*1+1) := otn_oh.TCM3_TTI(7+8*tti_index downto 8*tti_index);
              data_512(pos-8*1 downto pos-8*2+1) := bip8_2 xor otn_oh.TCM3_BIP8;
              data_512(pos-8*2 downto pos-8*3+1) := otn_oh.TCM3_AUX;
              
              data_512(pos-8*3 downto pos-8*4+1) := otn_oh.TCM2_TTI(7+8*tti_index downto 8*tti_index);
              data_512(pos-8*4 downto pos-8*5+1) := bip8_2 xor otn_oh.TCM2_BIP8;
              data_512(pos-8*5 downto pos-8*6+1) := otn_oh.TCM2_AUX;
              
              data_512(pos-8*6 downto pos-8*7+1) := otn_oh.TCM1_TTI(7+8*tti_index downto 8*tti_index);
              data_512(pos-8*7 downto pos-8*8+1) := bip8_2 xor otn_oh.TCM1_BIP8;
              data_512(pos-8*8 downto pos-8*9+1) := otn_oh.TCM1_AUX;
              
              data_512(pos-8*9 downto pos-8*10+1) := otn_oh.PM_TTI(7+8*tti_index downto 8*tti_index);
              data_512(pos-8*10 downto pos-8*11+1) := bip8_2 xor otn_oh.PM_BIP8;
              data_512(pos-8*11 downto pos-8*12+1) := otn_oh.PM_AUX;
              
              data_512(pos-8*12 downto pos-8*14+1) := otn_oh.EXP;
              
              data_512(pos-8*14 downto pos-8*15+1) := otn_oh.OPU3_RES3;
              data_512(pos-8*15 downto pos-8*16+1) := otn_oh.OPU3_JC3 xor ("000000" & otn_oh.jc_seq(2*jc_index+1 downto 2*jc_index));

            end if;

            if test_conf.cbr_map = '1' and (otn_col <= 120) then  --CBR demapping of payload                

              if (otn_col = 1) then   -- OH CBR

                data_512(fas_pos-128 downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-128+1);
                cbr_ptr := cbr_ptr - 128;                

              elsif (otn_col = 40) or (otn_col = 80) then -- CBR 16FS
                
                data_512(fas_pos downto fas_pos-128+1) := cbr_data_512(cbr_ptr downto cbr_ptr-128+1);
                data_512(fas_pos-128 downto fas_pos-256+1) := X"ffffffffffffffffffffffffffffffff"; -- 16FS
                cbr_ptr := cbr_ptr - 128;

              elsif (otn_col < 120) then  -- CBR CBR

                data_512(fas_pos downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-256+1);
                cbr_ptr := cbr_ptr - 256;

              elsif (otn_col = 120) then  -- CBR FEC

                data_512(fas_pos downto fas_pos-128+1) := cbr_data_512(cbr_ptr downto cbr_ptr-128+1);
                cbr_ptr := cbr_ptr - 128;
                
              end if;
              
              if (cbr_ptr < 256) then
                
                cbr_en := '1';
                cbr_ptr := cbr_ptr + 256; 
                
                cbr_data_512(511 downto 256) := cbr_data_512(255 downto 0);
                cbr_data_512(255 downto 0) := cbr_data_256;

              end if;
              
            end if;  -- CBR demapping

  
            if (otn_col = 1) then
              otn_bip8(fas_pos,bip8_0,X"0003ffff",data_512);            
            elsif (otn_col < 120) then
              otn_bip8(fas_pos,bip8_0,X"ffffffff",data_512);
            elsif (otn_col = 120) then
              otn_bip8(fas_pos,bip8_0,X"ffff0000",data_512);
            end if;             
        
            otn_scramble(fas_pos,test_conf.otn_scr_inh_gen,scr_reg,'0',data_512);
            
            if (otn_col = 127) then
              otn_col := 0;
              otn_row := otn_row + 1;
            end if;  
            
          when 4 =>
            
            if (otn_col = 1) then
              pos := fas_pos-128;
            
              data_512(pos-8*0 downto pos-8*2+1) := otn_oh.GCC1;
              data_512(pos-8*2 downto pos-8*4+1) := otn_oh.GCC2;
              
              data_512(pos-8*4 downto pos-8*8+1) := otn_oh.APS;
              data_512(pos-8*8 downto pos-8*14+1) := otn_oh.ODU3_RES2;
                
               
              if (mfas = X"00") then
                data_512(pos-8*14 downto pos-8*15+1) := otn_oh.PT;
              elsif (mfas = X"01") then
                data_512(pos-8*14 downto pos-8*15+1) := otn_oh.vcPT;
              else 
                data_512(pos-8*14 downto pos-8*15+1) := X"00";
              end if;
              
              data_512(pos-8*15 downto pos-8*16+1) := X"00";  --NJO
              
            end if;
   
            if test_conf.cbr_map = '1' and (otn_col <= 120) then  --CBR mapping of payload                

              if (otn_col = 1) then   -- FEC OH(NJ0)  
                
                
                if otn_oh.jc_seq(2*jc_index+1 downto 2*jc_index) = "00" or otn_oh.jc_seq(2*jc_index+1 downto 2*jc_index) = "10" then
                  -- No justification. (no CBR mapping) set NJO=0
                  data_512(fas_pos-248 downto fas_pos-256+1) := X"00";
                    
                elsif otn_oh.jc_seq(2*jc_index+1 downto 2*jc_index) = "01" then
                
                  --Include NJO in mapping
                  data_512(fas_pos-248 downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-8+1);
                  cbr_ptr := cbr_ptr - 8;
                  
                elsif otn_oh.jc_seq(2*jc_index+1 downto 2*jc_index) = "11" then
                  
                  -- Exclude NJO & PJO in mapping. set NJO=0
                  data_512(fas_pos-248 downto fas_pos-256+1) := X"00";
                  
                else 
                  assert false report "Invalid JC bytes";
                end if;
                
              elsif (otn_col = 2) and otn_oh.jc_seq(2*jc_index+1 downto 2*jc_index) = "11"  then -- (PJO)CBR  CBR
              
                --assert (in_data_256(255 downto 255-8+1) = X"00") report "PJO not Zero";
                data_512(fas_pos downto fas_pos-8+1) := X"00";
                data_512(fas_pos-8 downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-256+1+8);
                cbr_ptr := cbr_ptr - 256 + 8;                      

              elsif (otn_col = 41) or (otn_col = 81) then -- 16FS CBR
                
                data_512(fas_pos downto fas_pos-128+1) := X"ffffffffffffffffffffffffffffffff"; -- 16FS
                data_512(fas_pos-128 downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-128+1);
                cbr_ptr := cbr_ptr - 128;

              elsif (otn_col < 120) then  -- CBR CBR

                data_512(fas_pos downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-256+1);
                cbr_ptr := cbr_ptr - 256;

              elsif (otn_col = 120) then  -- CBR CBR

                data_512(fas_pos downto fas_pos-256+1) := cbr_data_512(cbr_ptr downto cbr_ptr-256+1);
                cbr_ptr := cbr_ptr - 256;

                if jc_index = 0 then
                  jc_index := 15;
                else
                  jc_index := jc_index-1;
                end if;

              end if;
              
              if (cbr_ptr < 256) then
                
                cbr_en := '1';
                cbr_ptr := cbr_ptr + 256; 
                
                cbr_data_512(511 downto 256) := cbr_data_512(255 downto 0);
                cbr_data_512(255 downto 0) := cbr_data_256;

              end if;
              
            end if;  -- CBR demapping
 
   
            if (otn_col = 1) then
              otn_bip8(fas_pos,bip8_0,X"00000003",data_512);            
            elsif (otn_col < 120) then
              otn_bip8(fas_pos,bip8_0,X"ffffffff",data_512);
            elsif (otn_col = 120) then
              otn_bip8(fas_pos,bip8_0,X"ffffffff",data_512);
            end if;             
  
            otn_scramble(fas_pos,test_conf.otn_scr_inh_gen,scr_reg,'0',data_512);
             
            if (otn_col = 128) then
              otn_col := 0;
              otn_row := (otn_row + 1) mod 4;
              mfas := mfas + '1';
            end if;          
    
          when others => assert false report "Invalid state";
        end case; --OTN_row
        
        out_data <= data_512(511 downto 256);
        if (fas_pos < 511) then
          data_512(511 downto fas_pos+1) := data_512(255 downto fas_pos+1-256);
        end if; 
      
 
      
      when "01" =>  -- CBR Mapping 

        if false then
          
          
        else 

          case test_conf.prbs is
          when '0' =>  -- CBR Mapping mode counter
           
            for n in 31 downto 0 loop
              out_data(7+n*8 downto n*8) <= conv_std_logic_vector(cnt,8);
              cnt := cnt + 1;
            end loop;
                
          when '1' =>  -- CBR Mapping mode PRBS
  
            prbs31(prbs_reg,X"ffffffff",iout_data);      
            out_data <= iout_data;
          
          when others => 
          end case;  --prbs 
          
        end if; -- stm
        
      when others => assert false report "Invalid configuration";
    end case; --Conf type 
        
    end if;

  end process;
  

	 
end frm_gen_0;