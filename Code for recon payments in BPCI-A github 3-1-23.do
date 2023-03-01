****************************
***Importing and cleaning***
****************************

global path "/nfs/turbo/amryan-turbo/github"

****Reconciliation components files****

***Fall 2020***

import excel "$path/REDACTED_000_BPCI_Advanced_MY1&2_PP1TU2_PP2TU1_PP3_Reconciliation_Final_TP_Fall2020.xlsx", sheet("Reconciliation_Components") cellrange(A8:W27442) firstrow clear


drop in 1/3

rename CY18FY19  episode_count18_19
rename P target_price18_19
rename CY19FY19  episode_count19 
rename R target_price19
rename CY19FY20 episode_count19_20
rename T target_price19_20

replace PGPACH=trim(PGPACH)
replace PerformancePeriod=trim(PerformancePeriod)
replace EpisodeInitiatorBPID=trim(EpisodeInitiatorBPID)

foreach x in episode_count18_19 target_price18_19 episode_count19 target_price19 episode_count19_20 target_price19_20 {
	destring `x', replace
	sum `x'
}

egen episode_count = rowtotal(episode_count18_19 episode_count19 episode_count19_20)

gen target_price = (target_price18_19 * (episode_count18_19 / episode_count)) + (target_price19 * (episode_count19 / episode_count)) + (target_price19_20 * (episode_count19_20 / episode_count))

gen baseline_spend = target_price / .97

foreach x in episode_count  {
	bysort  EpisodeInitiatorBPID PerformancePeriod:  egen `x'm = sum(`x')
}

gen spend_share = baseline_spend * (episode_count / episode_countm)

bysort EpisodeInitiatorBPID PerformancePeriod:  egen baseline_spend_ave = sum(spend_share)
 
egen tag=tag(EpisodeInitiatorBPID PerformancePeriod)
keep if tag==1

keep EpisodeInitiatorBPID PerformancePeriod PGPACH baseline_spend_ave episode_countm
drop if PerformancePeriod=="PP3"
save "$path/recon components fall 2020.dta", replace
tab PGPACH PerformancePeriod
sum 

***spring 2021***

import excel "$path/REDACTED_00000_BPCI_Advanced_MY3_PP3TU1_PP4_Reconciliation_Final_TP_Spring2021.xlsx", sheet("Reconciliation_Components") cellrange(A7:V16170) firstrow clear

drop in 1/4

rename PerformancePeriodClinicalEpis episode_count20
rename FinalTargetPriceinRealDolla target_price20
rename R episode_count20_21
rename S target_price20_21

replace PGPACH=trim(PGPACH)
replace PerformancePeriod=trim(PerformancePeriod)
replace EpisodeInitiatorBPID=trim(EpisodeInitiatorBPID)

foreach x in episode_count20 target_price20 episode_count20_21 target_price20_21 {
	destring `x', replace
	sum `x'
}

egen episode_count = rowtotal(episode_count20 episode_count20_21)

gen target_price = (target_price20 * (episode_count20 / episode_count)) + (target_price20_21 * (episode_count20_21 / episode_count)) 

gen baseline_spend = target_price / .97

foreach x in episode_count  {
	bysort  EpisodeInitiatorBPID PerformancePeriod:  egen `x'm = sum(`x')
}

gen spend_share = baseline_spend * (episode_count / episode_countm)

bysort EpisodeInitiatorBPID PerformancePeriod:  egen baseline_spend_ave = sum(spend_share)
 
egen tag=tag(EpisodeInitiatorBPID PerformancePeriod)
keep if tag==1

keep EpisodeInitiatorBPID PerformancePeriod PGPACH baseline_spend_ave episode_countm
save "$path/recon components spring 2021.dta", replace
tab PGPACH PerformancePeriod
sum 


****Reconciliation report files ***

***fall 2020***

import excel "$path/REDACTED_000_BPCI_Advanced_MY1&2_PP1TU2_PP2TU1_PP3_Reconciliation_Final_TP_Fall2020.xlsx", sheet("Reconciliation_Report") cellrange(A5:R3576) firstrow clear

rename Step6 total_20_per 
rename O capped_pos_neg_recon_amount

foreach x in EpisodeInitiatorBPID PGPACH PerformancePeriod {
	replace `x' = trim(`x')
}

gen dataset="fall2020"

drop in 1/2

keep EpisodeInitiatorBPID PGPACH PerformancePeriod   total_20_per capped_pos_neg_recon_amount dataset


foreach x in  PGPACH    total_20_per capped_pos_neg_recon_amount dataset {
	rename `x' `x'f20
}

save "$path/recon report fall 2020.dta", replace

***spring 2021***

import excel "$path/REDACTED_00000_BPCI_Advanced_MY3_PP3TU1_PP4_Reconciliation_Final_TP_Spring2021.xlsx", sheet("Reconciliation_Report") cellrange(A5:S2414) firstrow clear

rename Step11 pos_neg_recon_amount 
rename Step9 cqs 
rename K cqs_adj_amt
rename Step12 adj_pos_neg_recon_amount
rename Step6 total_20_per
rename Step13 stop_loss_gain
rename O capped_pos_neg_recon_amount

drop in 1/2

destring pos_neg_recon_amount - capped_pos_neg_recon_amount total_20_per- PotentialReductionAmount, replace

foreach x in ParentBPID EpisodeInitiatorBPID PerformancePeriod {
	replace `x' = trim(`x')
}

keep ParentBPID EpisodeInitiatorBPID PerformancePeriod capped_pos_neg_recon_amount

save "$path/recon report spring 2021.dta", replace

*******Merging files*****

use "$path/recon components fall 2020.dta", clear
merge 1:1 EpisodeInitiatorBPID PerformancePeriod using "$path/recon report fall 2020.dta", gen(_merge1)
drop if PerformancePeriod=="PP3"
rename capped_pos_neg_recon_amountf20 capped_pos_neg_recon_amount
destring capped_pos_neg_recon_amount, replace
save "$path/merge spring 2020.dta", replace

use "$path/recon components spring 2021.dta", clear
merge 1:1 EpisodeInitiatorBPID PerformancePeriod using "$path/recon report spring 2021.dta", gen(_merge1)
save "$path/merge spring 2021.dta", replace

append using "$path/merge spring 2020.dta"

rename  episode_countm episode_total 
rename baseline_spend_ave spend_episode
gen total_spend_std = spend_episode * episode_total
gen recon_episode = capped_pos_neg_recon_amount / episode_total

drop PGPACHf20 total_20_perf20 datasetf20

save "$path/analytic file 1-25-23.dta", replace

*****************
***Analysis******
*****************

use "$path/analytic file 1-25-23.dta", clear


****Numbers for Results section****


foreach x in  PP1 PP2 PP3 PP4 {
	sum episode_total if PerformancePeriod=="`x'" 
		display `r(sum)'
		local episodesall`x' = `r(sum)'
		display `episodesall`x''
		local participantsall`x' = `r(N)'
	foreach y in ACH PGP {
		sum episode_total if PerformancePeriod=="`x'" & PGPACH=="`y'" 
		display `r(sum)'
		local episodes`y'`x' = `r(sum)'
		local participants`y'`x' = `r(N)'
	}
}


local i=0
foreach x in  PP1 PP2 PP3 PP4 {
	
	local i=`i' + 1
	
	reg recon_episode if PerformancePeriod=="`x'" [aweight=episode_total], robust
	matrix list r(table)
	local recon_episodeall`x'  = r(table)[1,1]
	local reconall`x' = r(table)[1,1] * `episodesall`x'' / 1000000
	local reconall`x'll=  r(table)[5,1] * `episodesall`x'' / 1000000
	local reconall`x'ul=  r(table)[6,1] * `episodesall`x'' / 1000000
	
	reg spend_episode if PerformancePeriod=="`x'" [aweight=episode_total], robust
	local spend_episodeall`x'  = r(table)[1,1]
	
	foreach z in recon_episode spend_episode {
	reg `z' if PerformancePeriod=="`x'" [aweight=episode_total]
	est store `z'
	}
	suest recon_episode spend_episode, robust
	nlcom _b[recon_episode_mean:_cons]/ _b[spend_episode_mean:_cons]
	matrix list r(table)
	local break_episodeall`x' = r(table)[1,1] * -100
	local break_episodeall`x'ul=  r(table)[5,1] * -100
	local break_episodeall`x'll=  r(table)[6,1] * -100
	
	if `i'==1 matrix duce = `reconall`x'' , `reconall`x'll' , `reconall`x'ul' , `recon_episodeall`x'' , `spend_episodeall`x'', `break_episodeall`x'' , `break_episodeall`x'll' , `break_episodeall`x'ul'
	else matrix duce= duce \ `reconall`x'' , `reconall`x'll' , `reconall`x'ul' , `recon_episodeall`x'' , `spend_episodeall`x'', `break_episodeall`x'' , `break_episodeall`x'll' , `break_episodeall`x'ul'
	
	foreach y in ACH PGP {
		
		sum recon_episode if PerformancePeriod=="`x'" & PGPACH=="`y'" [aweight=episode_total]
		local recon_episode_sd`y'`x' =`r(sd)'
		reg recon_episode if PerformancePeriod=="`x'" & PGPACH=="`y'" [aweight=episode_total], robust
		matrix list r(table)
		local recon_episode`y'`x' =r(table)[1,1]
		local recon`y'`x' = r(table)[1,1] *  `episodes`y'`x'' / 1000000
		local recon`y'`x'll=  r(table)[5,1] * `episodes`y'`x'' / 1000000
		local recon`y'`x'ul=  r(table)[6,1] * `episodes`y'`x'' / 1000000
		
		sum spend_episode if PerformancePeriod=="`x'" & PGPACH=="`y'" [aweight=episode_total]
		local spend_episode`y'`x' = `r(mean)'
		local spend_episode_sd`y'`x' =`r(sd)'
		
		foreach z in recon_episode spend_episode {
		reg `z' if PerformancePeriod=="`x'" & PGPACH=="`y'" [aweight=episode_total]
		est store `z'
		}
		suest recon_episode spend_episode, robust
		nlcom _b[recon_episode_mean:_cons]/ _b[spend_episode_mean:_cons]
		matrix list r(table)
		local break_episode`y'`x' = r(table)[1,1] * -100
		local break_episode`y'`x'ul=  r(table)[5,1] * -100
		local break_episode`y'`x'll=  r(table)[6,1] * -100
		
		matrix duce = duce \ `recon`y'`x'' , `recon`y'`x'll' , `recon`y'`x'ul' , `recon_episode`y'`x'', `spend_episode`y'`x'' , `break_episode`y'`x'' , `break_episode`y'`x'll' ,  `break_episode`y'`x'ul'
	}
}

matrix coln duce  = recon_total recon_total_ll recon_total_ul recon_epi spend_epi break_per break_per_ll break_per_ul

***Aggregate recon payments and CI***

sum episode_total 
	display `r(sum)'
	local episodesallpp1_pp4 = `r(sum)'
		
foreach z in recon_episode  {
	reg `z' [aweight=episode_total]
	display r(table)[1,1] * `episodesallpp1_pp4' / 1000000
	display r(table)[5,1] * `episodesallpp1_pp4' / 1000000
	display r(table)[6,1] * `episodesallpp1_pp4' / 1000000
	}

***Table 1****

foreach x in  PP1 PP2 PP3 PP4 {
	local i=1
	foreach y in ACH PGP {
		display "`y' `x'"
		display `participants`y'`x'' 
		if `i'==1 matrix `x' = `participants`y'`x'' 
		else matrix `x'= `x' \ `participants`y'`x'' 
		local i=`i' + 1
		display `episodes`y'`x'' 
		 matrix `x'= `x' \ `episodes`y'`x'' 
		display `spend_episode`y'`x''
		matrix `x'= `x' \ `spend_episode`y'`x''
		matrix `x'= `x' \ `spend_episode_sd`y'`x''
		display `recon_episode`y'`x''
		matrix `x'= `x' \ `recon_episode`y'`x''
		matrix `x'= `x' \ `recon_episode_sd`y'`x''
		display ""
		display ""
		
	}
}	
matrix table1 =PP1 , PP2, PP3 , PP4
matrix coln table1  = PP1 PP2 PP3 PP4
clear
svmat table1, names(matcol)

export excel using "$path/table1.xlsx",   firstrow(variables) replace



******Figure 1****

gen x_axis = _n in 1/12
svmat duce

twoway (bar duce1 x_axis if x_axis<=3, color(blue*.15) barwidth(.8)) (bar duce1 x_axis if x_axis>3 & x_axis<=6,   color(blue*.35) barwidth(.8)) (bar duce1 x_axis if x_axis>6 & x_axis<=9, color(blue*.6) barwidth(.8)) (bar duce1 x_axis if x_axis>9, color(blue) barwidth(.8))  (rcap duce2 duce3 x_axis, color(black)),  legend(order(1 "Period 1" 2 "Period 2" 3 "Period 3" 4 "Period 4" ) region(color(white)) lwidth(none) r(1)) graphregion(color(white) margin(large)) title("")  subtitle("Net reconciliation payments, in million $", size(medsmall) pos(11) ) ytitle("") xtitle("") xlabel(1 "All participants  " 2 "Hospitals  " 3 "Physician Groups  " 4 "All participants  " 5 "Hospitals  " 6 "Physician Groups  " 7 "All participants  " 8 "Hospitals  " 9 "Physician Groups  "  10 "All participants  " 11 "Hospitals  " 12 "Physician Groups  " , noticks angle(45)) ylabel(0 "0" 100 "100" 200 "200" 300 "300" 400 "400" , noticks angle(horizontal))

graph copy panel_a, replace
graph display panel_a
graph export "$path/figure 1 panel_a.tif", width(1000) replace
graph export "$path/figure 1 panel_a.svg", replace

twoway (bar duce6  x_axis if x_axis<=3, color(blue*.15) barwidth(.8)) (bar duce6  x_axis if x_axis>3 & x_axis<=6,  color(blue*.35) barwidth(.8)) (bar duce6  x_axis if x_axis>6 & x_axis<=9, color(blue*.6) barwidth(.8)) (bar duce6  x_axis if x_axis>9, color(blue) barwidth(.8)) (rcap duce7 duce8 x_axis, color(black)),  legend(order(1 "Period 1" 2 "Period 2" 3 "Period 3" 4 "Period 4" ) region(color(white)) lwidth(none) r(1)) graphregion(color(white) margin(large)) title("")  subtitle("Reduction in clinical spending for break even, %", pos(11) size(medsmall)) ytitle("") xtitle("") xlabel(1 "All participants  " 2 "Hospitals  " 3 "Physician Groups  " 4 "All participants  " 5 "Hospitals  " 6 "Physician Groups  " 7 "All participants  " 8 "Hospital  " 9 "Physician Groups  "  10 "All participants  " 11 "Hospitals  " 12 "Physician Group  " , noticks angle(45)) ylabel(0(-3)-9, angle(horizontal))

graph copy panel_b, replace
graph display panel_b
graph export "$path/figure 1 panel_b.tif", width(1000) replace
graph export "$path/figure 1 panel_b.svg", replace



