// ******************************************************
// Informacion contagiados
// ******************************************************
// Declarar carpeta de trabajo
cd "C:\Users\51990\Dropbox\My PC (MSI)\Downloads\covis\betsa"

// Instalar librerias adicionales
ssc install outreg2, replace // Tablas word
ssc install spmap, replace // Graficar mapas
ssc install geo2xy, replace // Mapas
ssc install schemepack, replace // Colores de Mapas
ssc install palettes, replace // Mas colores
ssc install colrspace // Colores

// Configuraciones
set scheme white_tableau, perm // Colores
graph set window fontface "Arial Narrow" // Fuente

// ******************************************************
// Informacion contagiados
// ******************************************************
import delimited using "Datos\positivos_covid.csv", delimiters(";") clear

// Eliminar vacios y crear identificador
drop if ubigeo == .
drop if edad == .
drop if fecha_resultado == .
gen ID = _n

// Generar grupos etareos
recode edad (0/0 = 0 under_one_year) (1/4 = 1 from_1_to_4) (5/9=2 from_5_to_9) (10/14= 3 from_10_to_14) (15/19= 4 from_15_to_19) (20/24 = 5 from_20_to_24) (25/29 = 6 from_25_to_29) (30/34 = 7 from_30_to_34) (35/39 = 8 from_35_to_39) (40/44 = 9 from_40_to_44) (45/49 = 10 from_45_to_49) (50/54 = 11 from_50_to_54) (55/59 = 12 from_55_to_59) (60/64 = 13 from_60_to_64) (65/69 = 14 from_65_to_69) (70/74 = 15 from_70_to_74) (75/80 = 16 from_75_to_80) (80/max=17 over_80_years), gen(agegrp)

// Generar grupos por olas
recode fecha_resultado (20200421/20201120 = 1 ola_1) (20210111/20210831 = 2 ola_2) (20211221/20220228 = 3 ola_3) (nonmissing = 0 ola_no), gen(olagrp)

// Generar variables de contagiados (total y por grupo) por distrito
egen contagiados_total = count(ID), by (ubigeo)
forval i=1/3 {
  egen contagiados_ola`i' = count(ID) if olagrp==`i', by (ubigeo)
}
forval i=0/17 {
  egen contagiados_agegroup`i' = count(ID) if agegrp==`i', by (ubigeo)
  forval j=1/3 {
    egen contagiados_agegroup`i'_ola`j' = count(ID) if agegrp==`i' & olagrp==`j', by (ubigeo)
  }
}

//Generar variable hombres contagiados por olas por dsitrito
egen contagiados_h_total = count(ID) if sexo== "MASCULINO" , by (ubigeo)
forval i=1/3 {
  egen contagiados_h_ola`i' = count(ID) if sexo== "MASCULINO" && olagrp==`i', by (ubigeo)
}

// Resumir info por distritos
collapse contagiados*, by(ubigeo)

// Guardar
save contagiados.dta, replace


// ******************************************************
// Informacion fallecidos
// ******************************************************
import delimited using "Datos\fallecidos_covid.csv", delimiters(";") clear

// Eliminar vacios y crear identificador
drop if ubigeo == .
drop if edad_declarada == .
drop if fecha_fallecimiento == .
gen ID = _n

// Generar grupos etareos
recode edad_declarada (0/0 = 0 under_one_year) (1/4 = 1 from_1_to_4) (5/9=2 from_5_to_9) (10/14= 3 from_10_to_14) (15/19= 4 from_15_to_19) (20/24 = 5 from_20_to_24) (25/29 = 6 from_25_to_29) (30/34 = 7 from_30_to_34) (35/39 = 8 from_35_to_39) (40/44 = 9 from_40_to_44) (45/49 = 10 from_45_to_49) (50/54 = 11 from_50_to_54) (55/59 = 12 from_55_to_59) (60/64 = 13 from_60_to_64) (65/69 = 14 from_65_to_69) (70/74 = 15 from_70_to_74) (75/80 = 16 from_75_to_80) (80/max=17 over_80_years), gen(agegrp)

// Generar grupos por olas
recode fecha_fallecimiento (20200421/20201120 = 1 ola_1) (20210111/20210831 = 2 ola_2) (20211221/20220228 = 3 ola_3) (nonmissing = 0 ola_no), gen(olagrp)

// Generar variables de fallecidos (total y por grupo) por distrito
egen fallecidos_total = count(ID), by (ubigeo)
forval i=1/3 {
  egen fallecidos_ola`i' = count(ID) if olagrp==`i', by (ubigeo)
}
forval i=0/17 {
  egen fallecidos_agegroup`i' = count(ID) if agegrp==`i', by (ubigeo)
  forval j=1/3 {
    egen fallecidos_agegroup`i'_ola`j' = count(ID) if agegrp==`i' & olagrp==`j', by (ubigeo)
  }
}

// Fallecidos hombres por olas
egen fallecidos_h_total = count(ID) if sexo== "MASCULINO" , by (ubigeo)
forval i=1/3 {
  egen fallecidos_h_ola`i' = count(ID) if sexo== "MASCULINO" && olagrp==`i', by (ubigeo)
}

// Resumir info por distritos
collapse fallecidos*, by(ubigeo)

// Guardar
save fallecidos.dta, replace


// ******************************************************
// Informacion Distrital
// ******************************************************
import excel using "Datos\distritos.xlsx", firstrow sheet(Distritos) cellrange(A1:HI2096) clear
drop if Distrito == ""

// Agregar info de contagiados
merge 1:1 ubigeo using contagiados.dta
drop _merge

// Agregar info de fallecidos
merge 1:1 ubigeo using fallecidos.dta
drop _merge

// Llenar 0s
replace fallecidos_total  = 0 if missing(fallecidos_total)
replace contagiados_total  = 0 if missing(contagiados_total)
replace fallecidos_h_total = 0 if missing(fallecidos_h_total)
replace contagiados_h_total  = 0 if missing(contagiados_h_total)
forval i=1/3 {
  replace fallecidos_ola`i'  = 0 if missing(fallecidos_ola`i')
  replace contagiados_ola`i'  = 0 if missing(contagiados_ola`i')
  replace fallecidos_h_ola`i' = 0 if missing(fallecidos_h_ola`i')
  replace contagiados_h_ola`i' = 0 if missing(contagiados_h_ola`i')
}
forval i=0/17 {
  replace fallecidos_agegroup`i'  = 0 if missing(fallecidos_agegroup`i')
  replace contagiados_agegroup`i'  = 0 if missing(contagiados_agegroup`i')
  forval j=1/3 {
    replace fallecidos_agegroup`i'_ola`j'  = 0 if missing(fallecidos_agegroup`i'_ola`j')
    replace contagiados_agegroup`i'_ola`j'  = 0 if missing(contagiados_agegroup`i'_ola`j')
  }
}

// Variables adicionales
destring PT_Poblacion, generate(poblacion_total) float // Poblacion total
destring Pob_VP, generate(poblacion_VP) float // Pob_VP
destring H2O_S, generate(h2o_s) float force // h2o_s
destring Pob_SH, generate(poblacion_SH) float // Pob_SH
destring SH_DesagueDentro, generate(sh_desaguedentro) float force // sh_desaguedentro
destring SH_DesagueFuera, generate(sh_desaguefuera) float force // sh_desaguefuera
destring SH_PozoSeptico, generate(sh_pozoseptico) float force // sh_pozoseptico
destring SH_Letrina, generate(sh_letrina) float force // sh_letrina
destring SH_Pozociego, generate(sh_pozociego) float force // sh_pozociego
destring SH_Rioyacequia, generate (sh_rioyacequia) float force // sh_rioyacequia 
destring SH_CampoAbierto, generate (sh_campoabierto) float force // sh_campoabierto 
gen densidad = poblacion_total/Km2 // Densidad
gen h2o_s_pctg = 100*h2o_s/poblacion_VP
gen poblacion_VP_pctg = 100*poblacion_VP/poblacion_total
gen poblacion_SH_pctg = 100*poblacion_SH/poblacion_VP
gen poblacion_SH_DD_pctg = 100*sh_desaguedentro/poblacion_VP
gen poblacion_SH_DF_pctg = 100*sh_desaguefuera/poblacion_VP
gen poblacion_SH_PS_pctg = 100*sh_pozoseptico/poblacion_VP
gen poblacion_SH_RA_pctg = 100*sh_rioyacequia/poblacion_VP
gen poblacion_SH_CA_pctg = 100*sh_campoabierto/poblacion_VP

// Porcentaje de grupos etareos
destring menos1a, generate (agegrp0) float force
destring a4, generate (agegrp1) float force  
destring a9, generate (agegrp2) float force
destring a14, generate (agegrp3) float force
destring a19, generate (agegrp4) float force
destring a24, generate (agegrp5) float force
destring a29, generate (agegrp6) float force
destring a34, generate (agegrp7) float force
destring a39, generate (agegrp8) float force
destring a44, generate (agegrp9) float force
destring a49, generate (agegrp10) float force
destring a54, generate (agegrp11) float force
destring a59, generate (agegrp12) float force
destring a64, generate (agegrp13) float force
destring a69, generate (agegrp14) float force
destring a74, generate (agegrp15) float force
destring a80, generate (agegrp16) float force
destring mayor80, generate (agegrp17) float force
gen agegrp0_pctg = 100 * agegrp0 / poblacion_total
gen agegrp1_pctg = 100 * agegrp1 / poblacion_total
gen agegrp2_pctg = 100 * agegrp2 / poblacion_total
gen agegrp3_pctg = 100 * agegrp3 / poblacion_total
gen agegrp4_pctg = 100 * agegrp4 / poblacion_total
gen agegrp5_pctg = 100 * agegrp5 / poblacion_total
gen agegrp6_pctg = 100 * agegrp6 / poblacion_total
gen agegrp7_pctg = 100 * agegrp7 / poblacion_total
gen agegrp8_pctg = 100 * agegrp8 / poblacion_total
gen agegrp9_pctg = 100 * agegrp9 / poblacion_total
gen agegrp10_pctg = 100 * agegrp10 / poblacion_total
gen agegrp11_pctg = 100 * agegrp11 / poblacion_total
gen agegrp12_pctg = 100 * agegrp12 / poblacion_total
gen agegrp13_pctg = 100 * agegrp13 / poblacion_total
gen agegrp14_pctg = 100 * agegrp14 / poblacion_total
gen agegrp15_pctg = 100 * agegrp15 / poblacion_total
gen agegrp16_pctg = 100 * agegrp16 / poblacion_total
gen agegrp17_pctg = 100 * agegrp17 / poblacion_total


// Porcentaje de hombres
destring PT_PMasc, generate(poblacion_hombres) float
gen hombres_pctg = 100*poblacion_hombres/poblacion_total

// Mortalidad
gen mortalidad_total = 1000*fallecidos_total/poblacion_total
gen mortalidad_h_total = 1000*fallecidos_h_total/poblacion_hombres
forval i=1/3 {
  gen mortalidad_ola`i' = 1000*fallecidos_ola`i'/poblacion_total
  gen mortalidad_h_ola`i' = 1000*fallecidos_h_ola`i'/poblacion_hombres
}
forval i=0/17 {
  gen mortalidad_agegroup`i' = 1000*fallecidos_agegroup`i'/poblacion_total
  forval j=1/3 {
    gen mortalidad_agegroup`i'_ola`j' = 1000*fallecidos_agegroup`i'_ola`j'/poblacion_total
  }
}

// Letalidad
gen letalidad_total = 100*fallecidos_total/contagiados_total
gen letalidad_h_total = 100*fallecidos_h_total/contagiados_h_total
forval i=1/3 {
  gen letalidad_ola`i' = 100*fallecidos_ola`i'/contagiados_ola`i'
  gen letalidad_h_ola`i' = 100*fallecidos_h_ola`i'/contagiados_h_ola`i'
}
forval i=0/17 {
  gen letalidad_agegroup`i' = 100*fallecidos_agegroup`i'/contagiados_agegroup`i'
  forval j=1/3 {
    gen letalidad_agegroup`i'_ola`j' = 100*fallecidos_agegroup`i'_ola`j'/contagiados_agegroup`i'_ola`j'
  }
}

// Casos
gen contagiados_pctg_total = 100*contagiados_total/poblacion_total
forval i=1/3 {
  gen contagiados_pctg_ola`i' = 100*contagiados_ola`i'/poblacion_total
}
forval i=0/17 {
  gen contagiados_pctg_agegroup`i' = 100*contagiados_agegroup`i'/poblacion_total
  forval j=1/3 {
    gen contagiados_pctg_agegroup`i'_ola`j' = 100*contagiados_agegroup`i'_ola`j'/poblacion_total
  }
}

// Guardar
export excel using "base.xlsx", firstrow(variables) replace
save base.dta, replace


// ******************************************************
// Regresiones
// ******************************************************

// Labels
label variable densidad "Densidad"
label variable Pobreza_pctg "% pobreza"
label variable Pobreza_ext_pctg "% pobreza extrema"
label variable h2o_s_pctg "% acceso agua"
label variable poblacion_VP_pctg "% poblacion de viviendas particulares"
label variable poblacion_SH_pctg "% poblacion con servicios higienicos"
label variable agegrp0_pctg "% grupo etario 0"
label variable agegrp1_pctg "% grupo etario 1"
label variable agegrp2_pctg "% grupo etario 2"
label variable agegrp3_pctg "% grupo etario 3"
label variable agegrp4_pctg "% grupo etario 4"
label variable agegrp5_pctg "% grupo etario 5"
label variable agegrp6_pctg "% grupo etario 6"
label variable agegrp7_pctg "% grupo etario 7"
label variable agegrp8_pctg "% grupo etario 8"
label variable agegrp9_pctg "% grupo etario 9"
label variable agegrp10_pctg "% grupo etario 10"
label variable agegrp11_pctg "% grupo etario 11"
label variable agegrp12_pctg "% grupo etario 12"
label variable agegrp13_pctg "% grupo etario 13"
label variable agegrp14_pctg "% grupo etario 14"
label variable agegrp15_pctg "% grupo etario 15"
label variable agegrp16_pctg "% grupo etario 16"
label variable agegrp17_pctg "% grupo etario 17"

// Variables Desccripcion
outreg2 using "Resultados\descripcion_variables", replace sum(log) keep(Altitud Latitud densidad agegrp0_pctg agegrp1_pctg agegrp2_pctg agegrp3_pctg agegrp4_pctg agegrp5_pctg agegrp6_pctg agegrp7_pctg agegrp8_pctg agegrp9_pctg agegrp10_pctg agegrp11_pctg agegrp12_pctg agegrp13_pctg agegrp14_pctg agegrp15_pctg agegrp16_pctg agegrp17_pctg Pobreza_pctg Pobreza_ext_pctg poblacion_VP_pctg h2o_s_pctg poblacion_SH_pctg)

//Analisis bivariado
reg mortalidad_total Altitud [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word replace ctitle(x1) label
reg mortalidad_total Pobreza_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total Pobreza_ext_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total densidad [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total Latitud [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total h2o_s_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total poblacion_VP_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total poblacion_SH_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp0_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp1_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp2_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp3_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp4_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp5_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp6_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp7_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp8_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp9_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp10_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp11_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp12_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp13_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp14_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp15_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp16_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
reg mortalidad_total agegrp17_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_mortalidad", word append ctitle(x2) label
graph twoway (lfitci mortalidad_total Altitud) (scatter mortalidad_total Altitud)
graph twoway (lfitci mortalidad_total Pobreza_pctg) (scatter mortalidad_total Pobreza_pctg)
graph twoway (lfitci mortalidad_total Pobreza_ext_pctg) (scatter mortalidad_total Pobreza_ext_pctg)
graph twoway (lfitci mortalidad_total densidad) (scatter mortalidad_total densidad)
graph twoway (lfitci mortalidad_total Latitud) (scatter mortalidad_total Latitud)
graph twoway (lfitci mortalidad_total h2o_s_pctg) (scatter mortalidad_total h2o_s_pctg)
graph twoway (lfitci mortalidad_total poblacion_VP_pctg) (scatter mortalidad_total poblacion_VP_pctg)
graph twoway (lfitci mortalidad_total poblacion_SH_pctg) (scatter mortalidad_total poblacion_SH_pctg)
graph twoway (lfitci mortalidad_total agegrp0_pctg) (scatter mortalidad_total agegrp0_pctg)
graph twoway (lfitci mortalidad_total agegrp1_pctg) (scatter mortalidad_total agegrp1_pctg)
graph twoway (lfitci mortalidad_total agegrp2_pctg) (scatter mortalidad_total agegrp2_pctg)
graph twoway (lfitci mortalidad_total agegrp3_pctg) (scatter mortalidad_total agegrp3_pctg)
graph twoway (lfitci mortalidad_total agegrp4_pctg) (scatter mortalidad_total agegrp4_pctg)
graph twoway (lfitci mortalidad_total agegrp5_pctg) (scatter mortalidad_total agegrp5_pctg)
graph twoway (lfitci mortalidad_total agegrp6_pctg) (scatter mortalidad_total agegrp6_pctg)
graph twoway (lfitci mortalidad_total agegrp7_pctg) (scatter mortalidad_total agegrp7_pctg)
graph twoway (lfitci mortalidad_total agegrp8_pctg) (scatter mortalidad_total agegrp8_pctg)
graph twoway (lfitci mortalidad_total agegrp9_pctg) (scatter mortalidad_total agegrp9_pctg)
graph twoway (lfitci mortalidad_total agegrp10_pctg) (scatter mortalidad_total agegrp10_pctg)
graph twoway (lfitci mortalidad_total agegrp11_pctg) (scatter mortalidad_total agegrp11_pctg)
graph twoway (lfitci mortalidad_total agegrp12_pctg) (scatter mortalidad_total agegrp12_pctg)
graph twoway (lfitci mortalidad_total agegrp13_pctg) (scatter mortalidad_total agegrp13_pctg)
graph twoway (lfitci mortalidad_total agegrp14_pctg) (scatter mortalidad_total agegrp14_pctg)
graph twoway (lfitci mortalidad_total agegrp15_pctg) (scatter mortalidad_total agegrp15_pctg)
graph twoway (lfitci mortalidad_total agegrp16_pctg) (scatter mortalidad_total agegrp16_pctg)
graph twoway (lfitci mortalidad_total agegrp17_pctg) (scatter mortalidad_total agegrp17_pctg)

reg letalidad_total Altitud [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word replace ctitle(x1) label
reg letalidad_total Pobreza_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total Pobreza_ext_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total densidad [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total Latitud [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total h2o_s_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total poblacion_VP_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total poblacion_SH_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp0_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp1_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp2_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp3_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp4_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp5_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp6_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp7_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp8_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp9_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp10_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp11_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp12_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp13_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp14_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp15_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp16_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
reg letalidad_total agegrp17_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_letalidad", word append ctitle(x2) label
graph twoway (lfitci letalidad_total Altitud) (scatter letalidad_total Altitud)
graph twoway (lfitci letalidad_total Pobreza_pctg) (scatter letalidad_total Pobreza_pctg)
graph twoway (lfitci letalidad_total Pobreza_ext_pctg) (scatter letalidad_total Pobreza_ext_pctg)
graph twoway (lfitci letalidad_total densidad) (scatter letalidad_total densidad)
graph twoway (lfitci letalidad_total Latitud) (scatter letalidad_total Latitud)
graph twoway (lfitci letalidad_total h2o_s_pctg) (scatter letalidad_total h2o_s_pctg)
graph twoway (lfitci letalidad_total poblacion_VP_pctg) (scatter letalidad_total poblacion_VP_pctg)
graph twoway (lfitci letalidad_total poblacion_SH_pctg) (scatter letalidad_total poblacion_SH_pctg)
graph twoway (lfitci letalidad_total agegrp0_pctg) (scatter letalidad_total agegrp0_pctg)
graph twoway (lfitci letalidad_total agegrp1_pctg) (scatter letalidad_total agegrp1_pctg)
graph twoway (lfitci letalidad_total agegrp2_pctg) (scatter letalidad_total agegrp2_pctg)
graph twoway (lfitci letalidad_total agegrp3_pctg) (scatter letalidad_total agegrp3_pctg)
graph twoway (lfitci letalidad_total agegrp4_pctg) (scatter letalidad_total agegrp4_pctg)
graph twoway (lfitci letalidad_total agegrp5_pctg) (scatter letalidad_total agegrp5_pctg)
graph twoway (lfitci letalidad_total agegrp6_pctg) (scatter letalidad_total agegrp6_pctg)
graph twoway (lfitci letalidad_total agegrp7_pctg) (scatter letalidad_total agegrp7_pctg)
graph twoway (lfitci letalidad_total agegrp8_pctg) (scatter letalidad_total agegrp8_pctg)
graph twoway (lfitci letalidad_total agegrp9_pctg) (scatter letalidad_total agegrp9_pctg)
graph twoway (lfitci letalidad_total agegrp10_pctg) (scatter letalidad_total agegrp10_pctg)
graph twoway (lfitci letalidad_total agegrp11_pctg) (scatter letalidad_total agegrp11_pctg)
graph twoway (lfitci letalidad_total agegrp12_pctg) (scatter letalidad_total agegrp12_pctg)
graph twoway (lfitci letalidad_total agegrp13_pctg) (scatter letalidad_total agegrp13_pctg)
graph twoway (lfitci letalidad_total agegrp14_pctg) (scatter letalidad_total agegrp14_pctg)
graph twoway (lfitci letalidad_total agegrp15_pctg) (scatter letalidad_total agegrp15_pctg)
graph twoway (lfitci letalidad_total agegrp16_pctg) (scatter letalidad_total agegrp16_pctg)
graph twoway (lfitci letalidad_total agegrp17_pctg) (scatter letalidad_total agegrp17_pctg)

reg contagiados_pctg_total Altitud [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word replace ctitle(x1) label
reg contagiados_pctg_total Pobreza_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total Pobreza_ext_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total densidad [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total Latitud [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total h2o_s_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total poblacion_VP_pctg [weight=poblacion_total]
estat hettest
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total poblacion_SH_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp0_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp1_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp2_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp3_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp4_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp5_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp6_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp7_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp8_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp9_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp10_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp11_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp12_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp13_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp14_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp15_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp16_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
reg contagiados_pctg_total agegrp17_pctg [weight=poblacion_total]
estat hettest 
outreg2 using "Resultados\analisis_bivariado_contagiados", word append ctitle(x2) label
graph twoway (lfitci contagiados_pctg_total Altitud) (scatter contagiados_pctg_total Altitud)
graph twoway (lfitci contagiados_pctg_total Pobreza_pctg) (scatter contagiados_pctg_total Pobreza_pctg)
graph twoway (lfitci contagiados_pctg_total Pobreza_ext_pctg) (scatter contagiados_pctg_total Pobreza_ext_pctg)
graph twoway (lfitci contagiados_pctg_total densidad) (scatter contagiados_pctg_total densidad)
graph twoway (lfitci contagiados_pctg_total Latitud) (scatter contagiados_pctg_total Latitud)
graph twoway (lfitci contagiados_pctg_total h2o_s_pctg) (scatter contagiados_pctg_total h2o_s_pctg)
graph twoway (lfitci contagiados_pctg_total poblacion_VP_pctg) (scatter contagiados_pctg_total poblacion_VP_pctg)
graph twoway (lfitci contagiados_pctg_total poblacion_SH_pctg) (scatter contagiados_pctg_total poblacion_SH_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp0_pctg) (scatter contagiados_pctg_total agegrp0_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp1_pctg) (scatter contagiados_pctg_total agegrp1_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp2_pctg) (scatter contagiados_pctg_total agegrp2_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp3_pctg) (scatter contagiados_pctg_total agegrp3_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp4_pctg) (scatter contagiados_pctg_total agegrp4_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp5_pctg) (scatter contagiados_pctg_total agegrp5_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp6_pctg) (scatter contagiados_pctg_total agegrp6_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp7_pctg) (scatter contagiados_pctg_total agegrp7_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp8_pctg) (scatter contagiados_pctg_total agegrp8_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp9_pctg) (scatter contagiados_pctg_total agegrp9_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp10_pctg) (scatter contagiados_pctg_total agegrp10_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp11_pctg) (scatter contagiados_pctg_total agegrp11_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp12_pctg) (scatter contagiados_pctg_total agegrp12_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp13_pctg) (scatter contagiados_pctg_total agegrp13_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp14_pctg) (scatter contagiados_pctg_total agegrp14_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp15_pctg) (scatter contagiados_pctg_total agegrp15_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp16_pctg) (scatter contagiados_pctg_total agegrp16_pctg)
graph twoway (lfitci contagiados_pctg_total agegrp17_pctg) (scatter contagiados_pctg_total agegrp17_pctg)

// Lista de variables independients comunes
local var_dep Altitud Latitud Pobreza_pctg Pobreza_ext_pctg densidad agegrp1_pctg agegrp2_pctg agegrp3_pctg agegrp4_pctg agegrp5_pctg agegrp6_pctg agegrp7_pctg agegrp8_pctg agegrp9_pctg agegrp10_pctg agegrp11_pctg agegrp12_pctg agegrp13_pctg agegrp14_pctg agegrp15_pctg agegrp16_pctg agegrp17_pctg h2o_s_pctg poblacion_VP_pctg poblacion_SH_pctg poblacion_SH_DD_pctg poblacion_SH_DF_pctg poblacion_SH_CA_pctg poblacion_SH_PS_pctg poblacion_SH_RA_pctg[weight=poblacion_total]

// Regresiones todos los grupos etareos
regress mortalidad_ola1 `var_dep'
outreg2 using "Resultados\mortalidad_total", word replace ctitle(Ola 1) label
regress mortalidad_ola2 `var_dep'
outreg2 using "Resultados\mortalidad_total", word append ctitle(Ola 2) label
regress mortalidad_ola3 `var_dep'
outreg2 using "Resultados\mortalidad_total", word append ctitle(Ola 3) label
regress mortalidad_total `var_dep'
estat hettest 
outreg2 using "Resultados\mortalidad_total", word append ctitle(Total) label

// Regresiones por grupo etareo
forval i=0/17 {
  regress mortalidad_agegroup`i'_ola1 `var_dep'
  outreg2 using "Resultados\mortalidad_agegroup`i'", word replace ctitle(Ola 1) label
  regress mortalidad_agegroup`i'_ola2 `var_dep'
  outreg2 using "Resultados\mortalidad_agegroup`i'", word append ctitle(Ola 2) label
  regress mortalidad_agegroup`i'_ola3 `var_dep'
  outreg2 using "Resultados\mortalidad_agegroup`i'", word append ctitle(Ola 3) label
  regress mortalidad_agegroup`i' `var_dep'
  outreg2 using "Resultados\mortalidad_agegroup`i'", word append ctitle(Total) label
}

// Regresiones todos los grupos etareos
regress letalidad_ola1 `var_dep'
outreg2 using "Resultados\letalidad_total", word replace ctitle(Ola 1) label
regress letalidad_ola2 `var_dep'
outreg2 using "Resultados\letalidad_total", word append ctitle(Ola 2) label
regress letalidad_ola3 `var_dep'
outreg2 using "Resultados\letalidad_total", word append ctitle(Ola 3) label
regress letalidad_total `var_dep'
outreg2 using "Resultados\letalidad_total", word append ctitle(Total) label

// Regresiones por grupo etareo
forval i=0/17 {
  regress letalidad_agegroup`i'_ola1 `var_dep'
  outreg2 using "Resultados\letalidad_agegroup`i'", word replace ctitle(Ola 1) label
  regress letalidad_agegroup`i'_ola2 `var_dep'
  outreg2 using "Resultados\letalidad_agegroup`i'", word append ctitle(Ola 2) label
  regress letalidad_agegroup`i'_ola3 `var_dep'
  outreg2 using "Resultados\letalidad_agegroup`i'", word append ctitle(Ola 3) label
  regress letalidad_agegroup`i' `var_dep'
  outreg2 using "Resultados\letalidad_agegroup`i'", word append ctitle(Total) label
}

// Regresiones todos los grupos etareos
regress contagiados_pctg_ola1 `var_dep'
outreg2 using "Resultados\contagiados_pctg_total", word replace ctitle(Ola 1) label
regress contagiados_pctg_ola2 `var_dep'
outreg2 using "Resultados\contagiados_pctg_total", word append ctitle(Ola 2) label
regress contagiados_pctg_ola3 `var_dep'
outreg2 using "Resultados\contagiados_pctg_total", word append ctitle(Ola 3) label
regress contagiados_pctg_total `var_dep'
outreg2 using "Resultados\contagiados_pctg_total", word append ctitle(Total) label

// Regresiones por grupo etareo
forval i=0/17 {
  regress contagiados_pctg_agegroup`i'_ola1 `var_dep'
  outreg2 using "Resultados\contagiados_pctg_agegroup`i'", word replace ctitle(Ola 1) label
  regress contagiados_pctg_agegroup`i'_ola2 `var_dep'
  outreg2 using "Resultados\contagiados_pctg_agegroup`i'", word append ctitle(Ola 2) label
  regress contagiados_pctg_agegroup`i'_ola3 `var_dep'
  outreg2 using "Resultados\contagiados_pctg_agegroup`i'", word append ctitle(Ola 3) label
  regress contagiados_pctg_agegroup`i' `var_dep'
  outreg2 using "Resultados\contagiados_pctg_agegroup`i'", word append ctitle(Total) label
}
// ******************************************************
// Mapa
// ******************************************************

// Generar y abrir datos del mapa
spshape2dta "Mapas\DISTRITOS.shp", replace saving(distritos)
use distritos, clear

// Combinar con base de datos
destring IDDIST, generate(ubigeo)
merge 1:1 ubigeo using base.dta

// Graficar
colorpalette inferno, n(10) nograph reverse
local colors `r(p)'
spmap mortalidad_total using distritos_shp, ///
 id(_ID) cln(10)  fcolor("`colors'") ///
 ocolor(gs6 ..) osize(0.03 ..) ///
 ndfcolor(gs14) ndocolor(gs6 ..) ndsize(0.03 ..) ndlabel("Sin data") ///
 legend(pos(7) size(2.5))  legstyle(2) ///
 title("{fontface Times New Roman:Mortalidad del COVID-19 por distrito}", size(medsmall)) ///
 note("{fontface Times New Roman: Fuente: Minsa (2022), INEI (20??)}", size(1.5))

// Guardar grafico
graph export "Resultados\mapamortalidad.png", width(893) height(1290) replace
