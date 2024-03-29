library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(ggrepel)
library(ggmap)
library(viridis)
library(shonarrr)
library(pals)

#compile me please
calc_background = function(dat){
  background = dat %>% 
    filter(ship == "background") %>% 
    select(name, 
           background = value,
           uncert_b = uncertainty) %>% 
    group_by(name) %>% 
    summarise_all(mean, na.rm = T)
  
  
  ships = dat %>% 
    filter(ship != "background") %>% 
    left_join(background, by = "name") %>% 
    mutate(enhancement = value-background,
           uncert_e = uncertainty + uncert_b)
  
  #
  ships
  
}




# Read --------------------------------------------------------------------

#ACRUISE-2
setwd("G:/My Drive/ACRUISE/ACRUISE2/GC")
voc = read.csv("ACRUISE-2_gc_ships_r1.csv") %>% 
  tibble()

#ACRUISE-1
setwd("G:/My Drive/ACRUISE/ACRUISE1/VOC")
voc = read.csv("acruise1_vocs_tidy_with_ships.csv") %>% 
  tibble()

# shhip <- as.data.frame(c(0.942, 0.002, 0.732, 0.871, 1.004, 2.033, 1.954, 0.616, 0.789, 0.587, 0.673, 0.685, 0.783, 0.695, 0.706, 0.678, 0.786))
# shhip$lab <- "ship"
# shhip <- shhip %>% rename("ethane_area" = "c(0.942, 0.002, 0.732, 0.871, 1.004, 2.033, 1.954, 0.616, 0.789, 0.587, 0.673, 0.685, 0.783, 0.695, 0.706, 0.678, 0.786)")
# 
# test <- left_join(voc, shhip, keep = T)


# Tidy --------------------------------------------------------------------


# labels
colOrder = c("carbon_dioxide","methane","ethane","ethene","propane","propene",
             "iso_butane","n_butane","acetylene",
             "but_1_ene","iso_butene","iso_pentane",
             "n_pentane","cis_2_pentene","benzene",
             "ethylbenzene","toluene","p_xylene", "m_xylene","o_xylene") # order of VOCs (otherwise alphabetical)

colNames <-  labeller(name =
           c("carbon_dioxide" = "carbon dioxide - 400 ppm",
             "iso_butane" = "iso-butane",
             "n_butane" = "n-butane",
             "but_1_ene" = "but-1-ene",
             "iso_butene" = "iso-butene",
             "iso_pentane" = "iso-pentane",
             "n_pentane" = "n-pentane",
             "cis_2_pentene" = "cis-2-pentene",
             "p_xylene" = "p-xylene", 
             "m_xylene" = "m-xylene",
             "o_xylene" = "o-xylene",
             "methane" = "methane - 1850 ppb",
             "ethane" = "ethane",
             "ethene" = "ethene",
             "propane" = "propane",
             "propene" = "propene",
             "acetylene" = "acetylene",
             "ethylbenzene" = "ethylbenzene",
             "toluene" = "toluene",
             "benzene" = "benzene"))
         
vocNames = colOrder[colOrder != "carbon_dioxide"] # make CO2 free list for ratios


# tidy the VOCs: A2
voc_long_noratio = voc %>% 
  select(-starts_with("X")) %>% # tidy weird excel column
  pivot_longer(-c(ship:file)) %>% # make long (values are measurement, uncertainty and flag)
  mutate(name = str_replace(name,  "_uncertainty","__uncertainty"), # make separator nice
         name = str_replace(name,  "_flag","__flag"),
         name = ifelse(str_detect(name, "__"), name, paste0(name, "__spec")) # give measurement a name
         ) %>% 
  separate(name, c("name","type"), "__") %>% # split into name and type of values 
  pivot_wider(names_from = "type", values_from = "value") %>% # widen the three value types (measurement, uncertainty and flag)
  rename(value = spec) %>% # rename spec to value for semantics
  mutate(value = ifelse(flag == 0, value, NA), # NA all level 2 flagged values
         ship = str_trim(ship, "both"), # remove whitespace frome ship names
         case_bottle = interaction(case,bottle), # make unique bottle ID
         name = factor(name,
                       levels = colOrder)) #order in more sensible way


# make CO2 ratios
co2_ratio = voc_long_noratio %>% 
  select(case, bottle, name, value) %>% 
  pivot_wider() %>% 
  pivot_longer(cols = all_of(vocNames)) %>% 
  mutate(co2ratio = (value/carbon_dioxide)*1000) %>% # * 1000 for prettier numbers
  select(-value) %>% 
  pivot_wider(values_from = co2ratio) %>% 
  select(-carbon_dioxide) %>% 
  pivot_longer(cols = all_of(vocNames), values_to = "co2ratio")


voc_long = left_join(voc_long_noratio, co2_ratio, by = c("case", "bottle", "name")) # put them together


#####################


# tidy the VOCs: A1
voc <- voc %>%
  select(Ship, everything()) 

#voc$Ship <- "backgr"

#A1
voc_ord <- rev(c("ethane","ethene","propane", "propene","iso.butane","n.butane","acetylene","butene1", "iso.butene","iso.pentane", "n.pentane","benzene"))

colNames <- c("ethane" = "ethane",
              "ethene" = "ethene",
              "propane" = "propane", 
              "propene" = "propene",
              "iso.butane" = "iso-butane",
              "n.butane" = "n-butane",
              "butene1" = "but-1-ene",
              "iso.butene" = "iso-butene",
              "iso.pentane" = "iso-pentane",
              "n.pentane" = "n-pentane",
              "acetylene" = "acetylene",
              "benzene" = "benzene")

voc_long = voc %>% 
  #select(-c(Peak, X, lat:end)) %>% # tidy weird excel column
  pivot_longer(-c(Ship:flight)) %>% # make long (values are measurement, uncertainty and flag)
  mutate(name = str_replace(name,  "_uncert","__uncertainty"), # make separator nice
         name = str_replace(name,  "_flag","__flag"),
         name = str_replace(name,  "_area",""),
         name = ifelse(str_detect(name, "__"), name, paste0(name, "__spec")) # give measurement a name
  ) %>% 
  separate(name, c("name","type"), "__") %>% # split into name and type of values 
  pivot_wider(names_from = "type", values_from = "value") %>% # widen the three value types (measurement, uncertainty and flag)
  rename(value = spec) %>% # rename spec to value for semantics
  mutate(value = ifelse(flag == 0, value, NA), # NA all level 2 flagged values
         case_bottle = interaction(case,bottle), # make unique bottle ID
         ship = str_trim(Ship, "both")#,
         #name = factor(name, levels = colOrder)
         ) #order in more sensible way

voc_long$Ship <- "backgr"

voc_long$Ship[voc_long$case_bottle %in% c(7.1,7.2,7.3)] <- "Hirado"
voc_long$Ship[voc_long$case_bottle %in% c(6.18,6.24,1.60,2.54,7.4)] <- "unknown"



###############

# # make toluene ratios (change line 49)
# toluene_ratio = voc_long_noratio %>% 
#   select(case, bottle, name, value) %>% 
#   pivot_wider() %>% 
#   pivot_longer(cols = all_of(vocNames)) %>% 
#   mutate(tolueneratio = (value/toluene)/50) %>% # 50 for prettier numbers
#   select(-value) %>% 
#   pivot_wider(values_from = tolueneratio) %>% 
#   select(-toluene) %>% 
#   pivot_longer(cols = all_of(vocNames), values_to = "tolueneratio")
# 
# voc_toluene = left_join(voc_long_noratio, toluene_ratio, by = c("case", "bottle", "name")) # put them together






# #subtract backgrounds
temp = voc_long %>%
  select(case_bottle, name, value, ship, uncertainty, co2ratio) %>%
  mutate(grp = case_when(
    # case_bottle %in% c("7.9", "7.14", "7.11", "7.12", "7.13", "7.10") ~ 1,
    #                      case_bottle %in% c("7.7", "7.6", "102.06", "102.07", "102.03") ~ 2,
    #                      case_bottle %in% c("7.04", "102.02", "102.05", "7.05", "102.04", "102.01") ~ 3,
                         # case_bottle %in% c("7.02", "6.16", "6.15", "7.03", "7.01", "101.8", "101.07", "101.6", "6.14", "101.05", "6.13", "101.4", "101.3") ~ 4,
      case_bottle %in% c("6.5", "6.10", "6.11", 
                         "101.1","101.2","6.4","6.6","6.7","6.8","6.9") ~ 5,
                         # case_bottle %in% c("4.15", "4.16", "4.10", "4.12", "4.13", "4.14", "4.11") ~ 6,
                         # case_bottle %in% c("3.15", "3.16", "4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "4.7", "4.8", "4.9") ~ 7,
                         # case_bottle %in% c("3.1", "3.11") ~ 8,
                         # case_bottle %in% c("3.13", "3.12", "3.14") ~ 9,
                         # case_bottle %in% c("2.10", "2.09", "2.11", "2.12", "2.13") ~ 10,
                         # case_bottle %in% c("3.01", "2.14", "2.15", "2.16") ~ 11,
                         # case_bottle %in% c("3.05", "3.02", "3.03", "3.04", "3.06", "3.07", "3.08", "3.09") ~ 12,
                         # case_bottle %in% c() ~ 13,
                         # case_bottle %in% c() ~ 14,
                         # case_bottle %in% c() ~ 15,
                         # case_bottle %in% c() ~ 16,
                         # case_bottle %in% c() ~ 17,
                         # case_bottle %in% c() ~ 18,
                         # case_bottle %in% c() ~ 19,
                         # case_bottle %in% c() ~ 20,
                         TRUE ~ NA_real_)) %>%
  filter(!is.na(grp)) %>%
  split(., f = .$grp) %>%
  map_df(calc_background)


temp %>% 
  ggplot()+
  geom_bar(aes(case_bottle, enhancement, fill = name), stat = "identity", position = "stack")


positions <- c("101.1","101.2","6.6","6.7","6.8","6.9","6.4")



temp %>% 
  pivot_longer(c(value, background, enhancement), names_to = "type")  %>% 
  mutate(name = factor(name,
                       levels = colOrder)) %>%
  filter(type=="enhancement") %>% 
  #filter(name!="ethylbenzene")%>% 
  ggplot()+
  geom_bar(aes(case_bottle, value, fill = name), stat = "identity", position = "stack")+
  geom_errorbar(aes(ymin=value-uncert_e, ymax=value+uncert_e,
                    x=case_bottle),
                width=.2,
                position=position_dodge(.9))+
  scale_x_discrete(limits = positions)+
  scale_fill_viridis(discrete=TRUE) +
  theme_bw()+
  theme(text = element_text(size=14), legend.title = element_blank())+
  facet_wrap(~name, 
             scales = "free_y",
             labeller = colNames)+
  labs(x= "Case.bottle", y="Enhancement (ppb)")+
  guides(fill="none")






# Plot --------------------------------------------------------------------


# selected flights by ship/species (matrix style)
voc_long %>% 
  filter(flight %in% c("C262")) %>% 
  filter(name %in% c("ethene", "propene", "acetylene", "but_1_ene", "n_pentane","cis_2_pentene")) %>% 
  filter(ship!="Gwn 2") %>% 
  ggplot()+
  scale_fill_viridis(discrete=TRUE) +
  geom_bar(aes(case_bottle, value, fill = name), position = "stack", stat = "identity", width=0.2)+
  scale_color_identity()+
  geom_point(aes(case_bottle, 0, colour=ifelse(ship=="background", "cornflowerblue", "darkorange1"), size=3))+
  facet_wrap(~name, scales = "free_y")+ # "name" - by species, "ship" - by ship
  labs(x="SWAS case / bottle", y="VOC content (ppb)")+
  theme_minimal() +
  theme(plot.title = element_blank(),  
        text = element_text(size=12, colour="black"),
        axis.text = element_text(colour="black"),
        legend.title = element_blank(),
        strip.text = element_text(colour = 'black'),
        panel.spacing.x = unit(0,"line"),
        panel.border = element_rect(color = "grey", fill = NA, size = 1), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())+
  guides(size="none", fill="none")

###################################################################

# selected flight by ship (in one line, good for background comparison)
voc_long %>% 
  filter(flight %in% c("C262")) %>% 
  filter(name != "methane" & name != "carbon_dioxide") %>% 
  ggplot()+
  geom_bar(aes(case_bottle, value, fill = name), position = "stack", stat = "identity")+
  scale_fill_viridis(discrete=TRUE) +
  facet_grid(~ship, 
             scales = "free_x", 
             space='free', 
             labeller = labeller(ship = label_wrap_gen(10)) # make the ship names behave
             )+ #sort by "ship" or "flight"
  labs(x="SWAS case / bottle", y="VOC content (ppb)")+
  theme_minimal() +
  theme(plot.title = element_blank(),  
        text = element_text(size=10, colour="black"),
        axis.text = element_text(colour="black"),
        #axis.text.y = element_blank(),
        legend.title = element_blank(),
        strip.text = element_text(colour = 'black'),
        panel.spacing.x = unit(0,"line"),
        panel.border = element_rect(color = "grey", fill = NA, size = 1), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())


# selected flight by ship - CO2 and CH4 (in one line, good for background comparison)
voc_long %>% 
  filter(flight %in% c("C262")) %>% 
   filter(name == "methane") %>% 
  #filter(name == "carbon_dioxide") %>% 
  ggplot()+
   geom_bar(aes(case_bottle, value-1800), position = "stack", stat = "identity", fill="darkgreen")+
  #geom_bar(aes(case_bottle, value-390), position = "stack", stat = "identity", fill="darkblue")+
  scale_fill_viridis(discrete=TRUE) +
  facet_grid(~ship, 
             scales = "free_x", 
             space='free', 
             labeller = labeller(ship = label_wrap_gen(10)) # make the ship names behave
  )+ #sort by "ship" or "flight"
   labs(x="SWAS case / bottle", y="CH4 content (ppb - 1800)")+
  #labs(x="SWAS case / bottle", y="CO2 content (ppm - 390)")+
  theme_minimal() +
  theme(plot.title = element_blank(),  
        text = element_text(size=10, colour="black"),
        axis.text = element_text(colour="black"),
        #axis.text.y = element_blank(),
        legend.title = element_blank(),
        strip.text = element_text(colour = 'black'),
        panel.spacing.x = unit(0,"line"),
        panel.border = element_rect(color = "grey", fill = NA, size = 1), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())+
  guides(scale="none")
















##################################################################################################################################################################################################################
# PLOTS THESIS

#A2
voc_ord <- rev(c("carbon_dioxide", "methane", "ethane","ethene","propane", "propene","iso_butane","n_butane","acetylene","but_1_ene", "iso_butene","iso_pentane", "n_pentane","cis_2_pentene","benzene", "ethylbenzene","toluene","p_xylene", "m_xylene","o_xylene"))


voc_nam <- rev(c("carbon dioxide", "methane", "ethane","ethene","propane", "propene","iso-butane","n-butane","acetylene","but-1-ene", "iso-butene","iso-pentane", "n-pentane","cis-2-pentene","benzene", "ethylbenzene","toluene","p-xylene", "m-xylene","o-xylene"))



#fix names of variables


#background - all flights
voc_long %>% 
  #filter(status == "out") %>% 
  filter(name != "methane") %>% 
  filter(name != "carbon_dioxide") %>% 
  #filter(flight=="C265") %>%
  #filter(case_bottle != 2.56) %>% 
   ggplot()+
  geom_bar(aes(case_bottle, value, 
               fill = factor(name, 
                             levels=voc_ord)),
           position = "stack", 
           stat = "identity")+
  scale_fill_manual(values=as.vector(cols25(18)),
                    labels=c(colNames))+
  geom_point(aes(case_bottle, 
                 0, 
                 colour=ifelse(Ship=="backgr", 
                               "background", 
                               "plume"), 
                 size=2,
                 shape=1,
                 stroke=2),
             )+
  scale_colour_viridis(discrete=T)+
  scale_shape_identity()+
  facet_grid(~flight, 
             scales = "free_x", 
             space='free')+
  labs(x="Bottles", 
       y="VOC content (ppb)")+
  theme_minimal() +
  theme(plot.title = element_blank(),  
        text = element_text(size=14),
        axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
        legend.title = element_blank(),
        panel.spacing.x = unit(0,"line"),
        panel.border = element_rect(color = "grey", 
                                    fill = NA, 
                                    size = 1), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())+
  guides(size="none")

#

# old plot still has the weirdly high bottle
### background - methane co2
voc_long %>% 
  filter(ship == "background") %>% 
  #filter(name == "methane") %>% 
  filter(name == "carbon_dioxide") %>% 
  ggplot()+
  #geom_bar(aes(case_bottle, value-1800), position = "stack", stat = "identity", fill="darkgreen")+
  geom_bar(aes(case_bottle, value-390), position = "stack", stat = "identity", fill="darkblue")+
  scale_fill_viridis(discrete=TRUE) +
  facet_grid(~flight, 
             scales = "free_x", 
             space='free', 
             labeller = labeller(ship = label_wrap_gen(10)))+ 
  #labs(x="SWAS case.bottle", y=bquote(''~CH[4]~(ppb)~-~1800~ppb*''))+
  labs(x="SWAS case.bottle", y=bquote(''~CO[2]~(ppm)~-~390~ppm*''))+
  theme_minimal() +
  theme(plot.title = element_blank(),  
        text = element_text(size=14),
        axis.text.x = element_text(size=12),
        legend.title = element_blank(),
        panel.spacing.x = unit(0,"line"),
        panel.border = element_rect(color = "grey", 
                                    fill = NA, 
                                    size = 1), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())+
  guides(scales="none")



#

#background vs plume - avg

voc_long$status <- "idk"
voc_long$status[voc_long$ship == "background"] <- "low"
voc_long$status[voc_long$case_bottle %in% c(1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 3.16, 4.7, 4.8, 4.5, 4.4, 4.3)] <- "low"
voc_long$status[voc_long$case_bottle %in% 
                c(106.3, 106.8, 106.5, #251
                  101.1, 101.2, 6.6, 6.7, 6.8, 6.9, 6.4, #261
                  2.1, 103.3, 103.4, 103.5, #255
                  3.6, 3.7, 2.11, 3.12, 2,13, #256
                  4.1, 4.9, #257
                  101.3, 101.4, #262
                  7.11, 7.10 #264
                  )] <- "plume"
voc_long$status[voc_long$flight == "C263" & voc_long$status == "low"] <- "high" #187

stat <- voc_long %>% 
  filter(name != "methane") %>% 
  filter(name != "carbon_dioxide") %>% 
  filter(status != "idk") %>%
  group_by(status, name) %>% # Also want to group by species
  mutate(name = factor(name, levels=rev(colOrder))) %>%  # Best to order factors before plotting
  summarise(avgvoc=mean(value, na.rm=T)) %>%
  ggplot() +
  geom_col(aes(x=status, y=avgvoc, fill=name)) +
  scale_fill_manual(values=as.vector(cols25(18)),
                    labels=c(voc_nam))+
  labs(x="Plume status", 
       y="Average VOC content (ppb)")+
  theme_minimal() +
  theme(plot.title = element_blank(),  
        text = element_text(size=14),
        axis.text.x = element_text(size=12),
        legend.title = element_blank())
#

sum(stat$avgvoc[stat$status == "low"])

stat$avgvoc[stat$name=="propane" & stat$status == "high"]



 ###

# average background per flight

voc_long %>% 
  filter(name != "methane") %>% 
  filter(name != "carbon_dioxide") %>% 
  filter(status != "idk") %>%
  group_by(status, name, flight) %>%                       # Also want to group by species
  mutate(name = factor(name, levels=rev(colOrder))) %>%  # Best to order factors before plotting
  summarise(avgvoc=mean(value, na.rm=T)) %>%
  ggplot() +
  geom_col(aes(x=status, y=avgvoc, fill=name)) +
  scale_fill_manual(values=as.vector(cols25(18)),
                    labels=c(voc_nam))+
  labs(x="Plume status", 
       y="Average VOC content (ppb)")+
  facet_wrap(~flight, 
             #scales = "free_y",
             labeller = colNames,
             nrow=3)+
  theme_minimal() +
  theme(plot.title = element_blank(),  
        text = element_text(size=14),
        axis.text.x = element_text(size=12),
        legend.title = element_blank())



#

### plume in out by species

voc_long %>% 
  filter(name != "methane") %>% 
  filter(name != "carbon_dioxide") %>% 
  filter(status != "idk") %>%
  group_by(status, name) %>%    # Also want to group by species
  mutate(name = factor(name, levels=colOrder)) %>%  # Best to order factors before plotting
  summarise(avgvoc=mean(value, na.rm=T)) %>%
  ggplot() +
  geom_col(aes(x=status, y=avgvoc, fill=name)) +
  scale_fill_manual(values=as.vector(pals::cols25(19)),
                    labels=c(voc_nam))+
  labs(x="Plume status", 
       y="Average VOC content (ppb)")+
  theme_minimal() +
  theme(plot.title = element_blank(),  
        text = element_text(size=14),
        axis.text.x = element_text(size=12),
        legend.title = element_blank())+
  facet_wrap(~name, 
             scales = "free_y",
             labeller = colNames,
             nrow=5)+
  guides(fill="none")



# Al Ghuwairiya

positions <- c("101.1","101.2","6.6","6.7","6.8","6.9","6.4")



voc_long %>% 
  mutate(name = factor(name, levels=colOrder)) %>%  
  #mutate(value = ifelse(name=="methane", value-1850, value)) %>%
  #mutate(value = ifelse(name=="carbon_dioxide", value-400, value)) %>%
  filter(ship == "Al Ghuwairiya") %>% 
  filter(name != "carbon_dioxide" ) %>%
  filter(name != "methane") %>%
  ggplot()+
  geom_bar(aes(case_bottle, co2ratio, 
               fill = factor(name, 
                             levels=voc_ord)),
           position = "stack", 
           stat = "identity")+
  scale_fill_viridis(discrete=T)+
  scale_shape_identity()+
  # geom_errorbar(aes(ymin=co2ratio-uncertainty, ymax=co2ratio+uncertainty,
  #                   x=case_bottle),
  #               width=.2,
  #               position=position_dodge(.9))+
  scale_x_discrete(limits = positions)+
  facet_wrap(~name, 
             scales = "free_y",
             labeller = colNames)+
  labs(x="Case.bottle", 
       y="VOC content ratio (ppb*1000/ppm)")+
  theme_bw() +
  theme(plot.title = element_blank(),  
        text = element_text(size=14)
        )+
  guides(fill="none")

#

# enhancements

temp %>% 
  pivot_longer(c(value, background, enhancement), names_to = "type")  %>% 
  mutate(name = factor(name,
                       levels = colOrder)) %>%
  filter(type=="enhancement") %>% 
  filter(name!="ethylbenzene")%>% 
  ggplot()+
  geom_bar(aes(case_bottle, value, fill = name), stat = "identity", position = "stack")+
  geom_errorbar(aes(ymin=value-uncert_e, ymax=value+uncert_e,
                    x=case_bottle),
                width=.2,
                position=position_dodge(.9))+
  scale_x_discrete(limits = positions)+
  scale_fill_viridis(discrete=TRUE) +
  theme_bw()+
  theme(text = element_text(size=14), legend.title = element_blank())+
  facet_wrap(~name, 
             scales = "free_y",
             labeller = colNames)+
  labs(x= "Case.bottle", y="Enhancement (ppb)")+
  guides(fill="none")

###

















###



















##################################################################################################################################################################################################################


###################################################################


# all bottles ordered by overall concentration and labeled by flight
plot_data = voc_long %>% 
  filter(ship == "background") %>% 
  filter(name != "methane" & name != "carbon_dioxide") %>% 
  nest_by(case_bottle) %>% 
  mutate(s = sum(data$value, na.rm = T),
         case_bottle = as.character(case_bottle)) %>% 
  arrange(desc(s)) %>% 
  mutate(case_bottle = factor(case_bottle, unique(case_bottle))) %>%
  unnest(data)

plot_lables = plot_data %>% 
  select(case_bottle, flight) %>% 
  distinct()

plot_data %>% 
  ggplot()+
  geom_bar(aes(case_bottle, value, fill = name), position = "stack", stat = "identity")+
  geom_text(data = plot_lables,
            aes(case_bottle, -0.1, label = flight))



# all bottles benzene/toluene ratio
voc_toluene %>% 
  filter(flight %in% c("C255")) %>% 
  filter(name == "toluene" | name == "benzene") %>% 
  ggplot()+
  geom_bar(aes(case_bottle, value, fill = name), position = "stack", stat = "identity")+
  geom_point(aes(case_bottle, tolueneratio), colour="white", fill="blue", size=5, pch=21)+
  scale_fill_viridis(discrete=TRUE) +
  facet_grid(~ship, 
             scales = "free_x", 
             space='free', 
             labeller = labeller(ship = label_wrap_gen(10)) # make the ship names behave
  )+ #sort by "ship" or "flight"
  labs(x="SWAS case / bottle", y="Benzene/toluene content (ppb) and ratio (/50)")+
  theme_minimal() +
  theme(plot.title = element_blank(),  
        text = element_text(size=10, colour="black"),
        axis.text = element_text(colour="black"),
        #axis.text.y = element_blank(),
        legend.title = element_blank(),
        strip.text = element_text(colour = 'black'),
        panel.spacing.x = unit(0,"line"),
        panel.border = element_rect(color = "grey", fill = NA, size = 1), 
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank())
                                                                                                                                      












# Map -------------------------------------------------


# get the swas latlon and flight track data
swas <- read.csv("G:/My Drive/ACRUISE/ACRUISE2/SWAS_ACRUISE2/swas_all_logs_r1.csv") %>% 
  select(-c("start","end")) %>%
  mutate(date=dmy_hms(date))
  
dm <- readRDS("G:/My Drive/ACRUISE/ACRUISE2/data_raw/core_for_stats/ACRUISE-2_merged_r0.RDS")

#pick flight
fn <- 261

# pick flight in flight track data
flights <- dm %>% filter(flight == fn) %>% na.omit()

# wind direction
flights$dirs = 180 + 180 * atan2(flights$V_C,flights$U_C) / pi


# make unique bottle ID and pick flight in swas data
bottles <-  swas %>% 
  filter(flight == fn) %>%
  mutate(bgrd_flag = ifelse(Ship=="background", 1, 0),
         bgrd_flag = ifelse(is.na(bgrd_flag),0,bgrd_flag))


# make map box
#bbox_cropped=c(min(flights$LON_GIN-0.1),min(flights$LAT_GIN-0.1),max(flights$LON_GIN+0.1),max(flights$LAT_GIN+0.1))
# bbox_cropped=c(-7.8,46.7,-5.2,48.5) #264
# bbox_cropped=c(-2.2, 49.8, 0, 50.7) #263
# bbox_cropped=c(-8,46.8,-5.5,48.5) #262
# bbox_cropped=c(-7.3,50.4,-5,51.3) #261
# bbox_cropped=c(-7.5,46.7,-5.5,49.1) #259
# bbox_cropped=c(-7.5,47,-5.5,49) #257
# bbox_cropped=c(-8,49.2,-4,50.3) #256
# bbox_cropped=c(-1.5,50,1.1,50.8) #255
# bbox_cropped=c(-7.5,47,-5.5,48.5) #254
# bbox_cropped=c(-2,50,0.75,50.7) #253
#bbox_cropped=c(-7.2,47.6,-5.8,48.3) #251

# make a map background
mymap = ggmap::get_stamenmap(bbox_cropped, zoom = 7)

# plot swas & flight tracks on the map
ggmap(mymap)+
  geom_point(data = flights, 
             aes(LON_GIN,
                 LAT_GIN, 
                 colour=dirs),
             size = 1,
             alpha = .7) +
  # geom_point(data=bottles,
  #            aes(LON_GIN,LAT_GIN),
  #            size = 2,
  #            shape=4,
  #            stroke=2,
  #            colour="deeppink4") +
  # geom_label_repel(data=bottles,
  #            aes(x=LON_GIN,
  #                y=LAT_GIN,
  #                label=bottle_id,
  #                colour=ifelse(bgrd_flag==1, "firebrick", "black")))+
  # scale_color_identity()+
  scale_colour_viridis()+
  theme_minimal() +
  theme(axis.title = element_blank())

#























# Notes -------------------------------------------------


# widening again
voc_long %>% 
  pivot_wider(names_from = "name",
              values_from = c(value,uncertainty,flag),
              names_glue = "{name}__{.value}") %>% 
  rename_all(~str_remove(.x,"__value"))


# plot all by bottle
plot_lables = voc_long %>% 
  filter(ship %in% "background") %>% 
  select(case_bottle, flight) %>% 
  mutate(y = -0.1) %>% 
  distinct()

voc_long %>% 
  filter(flight %in% c("background")) %>% 
  ggplot()+
  geom_bar(aes(case_bottle, value, fill = name), position = "stack", stat = "identity")+
  geom_text(data = plot_lables,
            aes(case_bottle, y, label=flight))+
  scale_fill_viridis(discrete=TRUE) +
  #facet_wrap(~ship, scales = "free_x")+
  labs(x="SWAS case / bottle", y="Percentage")+
  theme_minimal() +
  theme(plot.title = element_blank(),  text = element_text(size=14, colour="black"), axis.text = element_text(colour = "black"))


