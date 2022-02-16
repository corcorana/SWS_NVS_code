library(here)
library(tidyverse)
library(lme4)
library(car)
library(emmeans)
library(performance)
library(ordinal)
library(RVAideMemoire)

# global settings
options(contrasts = c("contr.Sum", "contr.poly"))

theme_set(theme_bw())
font_theme <- theme(
  axis.title.x = element_text(size = 20, face="bold"),
  axis.title.y = element_text(size = 20, face="bold"),
  axis.text.x = element_text(size = 20, face="bold"),
  axis.text.y = element_text(size = 20, color = "black"),
  strip.text.x = element_text(size = 20, face="bold"),
  strip.text.y = element_text(size = 20, face="bold"),
  legend.title = element_text(size = 20, face="bold"), 
  legend.text = element_text(size = 20, face="bold"),
  legend.position = "top"
)

colCond <- c(rgb(0.1054688, 0.6171875, 0.4648438),
             rgb(0.8476562, 0.3710938, 0.0078125),
             rgb(0.4570312, 0.4375000, 0.6992188)
)


# import data
dat <- tryCatch( # navigate from base dir, otherwise try local
  read.csv(file.path("stats", "wsws_timefrq.csv", fsep = .Platform$file.sep), header = TRUE),
  warning = function(w)
    read.csv("wsws_timefrq.csv", header = TRUE) )

# trim empty rows at foot of df, recode NaNs to NAs
data <- data[!is.nan(data$subj_id),]
data[data=="NaN"] <- NA

# impute missing block & trial number for 406, correct subsequent trial numbers (5 missing due to technical error)
data$block[is.na(data$block)] <- 3
data$trial[is.na(data$trial)] <- 44
data$trial[data$subj_id==406 & data$block>3 & data$trial>43] <- data$trial[data$subj_id==406 & data$block>3 & data$trial>43]+5

# create factors
data <- data %>% 
  mutate(subj_id = as.factor(subj_id),
         stim = as.factor(stim),
         cond = relevel(as.factor(cond), ref=3),
         freq = as.factor(freq),
         clarity1 = as.ordered(clarity1),
         clarity2 = as.ordered(clarity2),
         item_id = as.factor(item_id),
         chan_id = as.factor(chan)
  ) %>%
  droplevels()

levels(data$stim) <- list( SWS="1", NVS="2")
levels(data$cond) <- list( pos="1", neg="2", zero="3" )
levels(data$freq) <- list( Delta = "1", Theta="2", Alpha="3", Beta="4" )


## clarity ratings ###
clar <- data %>%
  filter(chan == 1 & freq == "Delta") %>%
  select(-freq, -chan, -chan_id) %>%
  drop_na(clarity1)

c0 <- clmm(clarity2 ~ clarity1 + trial + 
             (1|subj_id) + (1|item_id), 
           data = clar)	

c1 <- clmm(clarity2 ~ clarity1 + trial + stim + 
             (1+stim|subj_id) + (1|item_id), 
           data = clar)	

c2 <- clmm(clarity2 ~ clarity1 + trial + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id),
           data = clar)	

c3 <- clmm(clarity2 ~ clarity1 + trial + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id), 
           data = clar)	

anova(c0, c1, c2, c3)

# attempt to reduce slopes on c2
c2.0 <- clmm(clarity2 ~ clarity1 + trial + stim + cond + 
               (1|subj_id) + (1|item_id), 
             data = clar)	

c2.1 <- clmm(clarity2 ~ clarity1 + trial + stim + cond + 
               (1+stim|subj_id) + (1|item_id), 
             data = clar)	

c2.2 <- clmm(clarity2 ~ clarity1 + trial + stim + cond + 
               (1+cond|subj_id) + (1|item_id), 
             data = clar)	

anova(c2, c2.0, c2.1, c2.2)

# attempt to reduce random effects complexity
c3.0 <- clmm(clarity2 ~ clarity1 + trial + stim * cond + 
               (1|subj_id) + (1|item_id), 
             data = clar)	

c3.1 <- clmm(clarity2 ~ clarity1 + trial + stim * cond + 
               (1+stim|subj_id) + (1|item_id), 
             data = clar)	

c3.2 <- clmm(clarity2 ~ clarity1 + trial + stim * cond + 
               (1+cond|subj_id) + (1|item_id), 
             data = clar)	

c3.3 <- clmm(clarity2 ~ clarity1 + trial + stim * cond + 
             (1+stim+cond|subj_id) + (1|item_id), 
           data = clar)	

anova(c2, c3.0, c3.1, c3.2, c3.3)


# print anova & summary table for winning model
c.wm <- c3.2
Anova.clmm(c.wm, type=2)
summary(c.wm)

# post-hoc contrasts for winning model
pairs(emmeans(c.wm, ~stim))
pairs(emmeans(c.wm, ~cond))
contrast(emmeans(c.wm, ~cond*stim), interaction = "pairwise", adjust="sidak")


### spectral power ###
delta <- filter(data, freq=="Delta")
theta <- filter(data, freq=="Theta")
alpha <- filter(data, freq=="Alpha")
beta <- filter(data, freq=="Beta")


## delta-band
d0 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + 
             (1|subj_id) + (1|item_id) + (1|chan_id),
           data=delta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

d1 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim + 
             (1+stim|subj_id) + (1|item_id) + (1|chan_id),
           data=delta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

d2 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
           data=delta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

d3 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
           data=delta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(d0, d1, d2, d3)

# attempt to reduce random effects complexity
d3.1 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
               (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
             data=delta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(d3, d3.1)

# refit winning model with REML
d.wm <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
               (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
             data=delta, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

# print anova & summary table for winning model
Anova(d.wm)
summary(d.wm)

# post-hoc contrasts for winning model
pairs(emmeans(d.wm, ~cond))


## theta-band 
t0 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + 
             (1|subj_id) + (1|item_id) + (1|chan_id),
           data=theta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

t1 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim + 
             (1+stim|subj_id) + (1|item_id) + (1|chan_id),
           data=theta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

t2 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
           data=theta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

t3 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
           data=theta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(t0, t1, t2, t3)

# attempt to reduce random effects complexity
t3.1 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
               (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
             data=theta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(t3, t3.1)


# refit winning model with REML
t.wm <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
               (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
             data=theta, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

# print anova & summary table for winning model
Anova(t.wm)
summary(t.wm)

# post-hoc contrasts for winning model
pairs(emmeans(t.wm, ~cond))



## alpha-band 
a0 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + 
             (1|subj_id) + (1|item_id) + (1|chan_id),
           data=alpha, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

a1 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim + 
             (1+stim|subj_id) + (1|item_id) + (1|chan_id),
           data=alpha, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

a2 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
           data=alpha, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

a3 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
           data=alpha, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(a0, a1, a2, a3)

# attempt to reduce random effects complexity
a3.1 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
               (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
             data=alpha, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(a3, a3.1)


# refit winning model with REML
a.wm <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
               (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
             data=alpha, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

# print anova & summary table for winning model
Anova(a.wm)
summary(a.wm)

# post-hoc contrasts for winning model
pairs(emmeans(a.wm, ~cond))
contrast(emmeans(a.wm, ~cond*stim), interaction = "pairwise", adjust="sidak")


## beta-band 
b0 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + 
             (1|subj_id) + (1|item_id) + (1|chan_id),
           data=beta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

b1 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim + 
             (1+stim|subj_id) + (1|item_id) + (1|chan_id),
           data=beta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

b2 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
           data=beta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

b3 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
           data=beta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(b0, b1, b2, b3)

# attempt to reduce random effects complexity
b3.1 <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
             (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
           data=beta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

anova(b3, b3.1)

# refit winning model with REML
b.wm <- lmer(logpow2 ~ logpow1 + clarity1 + trial + stim * cond + 
               (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
             data=beta, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

# print anova & summary table for winning model
Anova(b.wm)
summary(b.wm)



### plot condition effect (marginalise over stim)

## refit to mean-centred data 
mc <- data %>%
  group_by(subj_id, freq) %>%
  summarise(muPow = mean(logpow2, na.rm=T)) %>%
  ungroup() %>%
  left_join(data, ., by=c("subj_id", "freq"))

mc$logpow2.mc <- (mc$logpow2 - mc$muPow)

m2 <- mc %>% 
  group_by(subj_id, cond, freq) %>% 
  summarise(l2 = mean(logpow2.mc, na.rm=T)) %>% 
  ungroup()%>%
  mutate( ji = jitter(as.numeric(cond), amount = .1) )


# subset freq bands & refit models to mean-centred data
delta.mc <- subset(mc, freq=="Delta")
theta.mc <- subset(mc, freq=="Theta")
alpha.mc <- subset(mc, freq=="Alpha")
beta.mc <- subset(mc, freq=="Beta")

d3.mc <- lmer(logpow2.mc ~ logpow1 + clarity1 + trial + stim*cond + 
                (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
              data=delta.mc, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

t3.mc <- lmer(logpow2.mc ~ logpow1 + clarity1 + trial + stim*cond + 
                (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
              data=theta.mc, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

a3.mc <- lmer(logpow2.mc ~ logpow1 + clarity1 + trial + stim*cond + 
                (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
              data=alpha.mc, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

b3.mc <- lmer(logpow2.mc ~ logpow1 + clarity1 + trial + stim*cond +
                (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
              data=beta.mc, REML = TRUE, control=lmerControl(optimizer="bobyqa") )


# collate EMMs
emmd <- as.data.frame(emmeans(d3.mc, ~cond))
emmd <- cbind(emmd, freq="Delta")

emmt <- as.data.frame(emmeans(t3.mc, ~cond))
emmt <- cbind(emmt, freq="Theta")

emma <- as.data.frame(emmeans(a3.mc, ~cond))
emma <- cbind(emma, freq="Alpha")

emmb <- as.data.frame(emmeans(b3.mc, ~cond))
emmb <- cbind(emmb, freq="Beta")

emms <- rbind(emmd, emmt, emma, emmb)


# prepare annotations
anno <- data.frame(x1 = c(2, 1, 1, 1, 2, 1), 
                   x2 = c(3, 3, 2, 3, 3, 3), 
                   y1 = c(.085, .120, .085, .120, .085, .120), 
                   y2 = c(.105, .140, .105, .140, .105, .140), 
                   xstar = c(2.5, 2, 1.5, 2, 2.5, 2), 
                   ystar = c(.11, .145, .11, .145, .11, .145),
                   lab = c("***", "*", "***", "*", "***", '***'),
                   freq = c("Delta", "Delta", "Theta", "Theta", "Alpha", "Alpha") )

# plot facet grid
ggplot() +
  geom_line(dat = m2,
            aes(x = ji, y = l2, group = subj_id), size=.7, alpha = .3 ) +
  geom_point(dat = m2,
             aes(x = ji, y = l2, fill = cond), size = 3, alpha = .3, stroke = 1.5, shape=21) +
  scale_y_continuous(name = "Power (a.u.)", limits = c(-.16, .16), breaks = c(-.1, 0, .1) ) +
  scale_x_continuous(name = " ", breaks = c(1:3), labels = c("P+","P-","P0")) +
  scale_fill_manual(values = colCond,
                    breaks=c("pos","neg","zero"), labels = c("P+","P-","P0") ) + 
  scale_shape_manual(values=c(21)) + 
  geom_errorbar(dat = emms,
                aes(x = as.numeric(cond), y = emmean, ymin = emmean-SE, ymax = emmean+SE), 
                width = .2, size = 1.2 ) +
  geom_line(dat = emms, 
            aes(x = as.numeric(cond), y = emmean), size=1.5, alpha = 1 ) +
  geom_point(dat = emms, 
             aes(x = as.numeric(cond), y = emmean, fill = cond), 
             size = 5, stroke = 2.5, shape = 21 ) +
  font_theme +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), legend.position = "none",
        axis.text.x = element_text(face="bold", color=colCond, size=24) ) +
  facet_wrap(.~freq) +
  geom_text(data = anno, aes(x = xstar,  y = ystar, label = lab), size= 11) +
  geom_segment(data = anno, aes(x = x1, xend = x1, 
                                y = y1, yend = y2) ) +
  geom_segment(data = anno, aes(x = x2, xend = x2, 
                                y = y1, yend = y2) ) +
  geom_segment(data = anno, aes(x = x1, xend = x2, 
                                y = y2, yend = y2) )


### plot Figure 3C -- only display significant condition effects (drop Beta model)
emms <- rbind(emmd, emmt, emma)
emms$freq <- factor(emms$freq, levels = c("Delta", "Theta", "Alpha"))
m3 <- m2 %>% filter(freq!="Beta") %>% droplevels()


# prepare annotations
anno <- data.frame(x1 = c(2, 1, 1, 1, 2, 1), 
                   x2 = c(3, 3, 2, 3, 3, 3), 
                   y1 = c(.085, .120, .085, .120, .085, .120), 
                   y2 = c(.095, .130, .095, .130, .095, .130), 
                   xstar = c(2.5, 2, 1.5, 2, 2.5, 2), 
                   ystar = c(.1, .135, .1, .135, .1, .135),
                   lab = c("***", "*", "***", "*", "***", '***'),
                   freq = factor(c("Delta", "Delta", "Theta", "Theta", "Alpha", "Alpha"), 
                                 levels = c("Delta", "Theta", "Alpha") ))


# plot facet grid
ggplot() +
  geom_line(dat = m3,
            aes(x = ji, y = l2, group = subj_id), size=.7, alpha = .3 ) +
  geom_point(dat = m3,
             aes(x = ji, y = l2, fill = cond), size = 3, alpha = .3, stroke = 1.5, shape=21) +
  scale_y_continuous(position = "right", name = "Power (a.u.)", 
                     limits = c(-.13, .14), breaks = c(-.10, -.05, 0, .05, .10), 
                     labels = c("-.10 ", "-.05 ", " 0", ".05", ".10") ) +
  scale_x_continuous(name = " ", breaks = c(1:3), labels = c("P+","P-","P0")) +
  scale_fill_manual(values = colCond,
                    breaks=c("pos","neg","zero"), labels = c("P+","P-","P0") ) + 
  scale_shape_manual(values=c(21)) + 
  geom_errorbar(dat = emms,
                aes(x = as.numeric(cond), y = emmean, ymin = emmean-SE, ymax = emmean+SE), 
                width = .2, size = 1.2 ) +
  geom_line(dat = emms, 
            aes(x = as.numeric(cond), y = emmean), size=1.5, alpha = 1 ) +
  geom_point(dat = emms, 
             aes(x = as.numeric(cond), y = emmean, fill = cond), 
             size = 5, stroke = 2.5, shape = 21 ) +
  font_theme +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), 
        legend.position = "none",
        axis.text.x = element_text(color=colCond, size = 24),
        strip.text.x = element_text(size = 24), 
        plot.background = element_rect(fill = "transparent", color = NA) ) +
  facet_wrap(.~freq) +
  geom_text(data = anno, aes(x = xstar,  y = ystar, label = lab), size= 10) +
  geom_segment(data = anno, aes(x = x1, xend = x1, 
                                y = y1, yend = y2) ) +
  geom_segment(data = anno, aes(x = x2, xend = x2, 
                                y = y1, yend = y2) ) +
  geom_segment(data = anno, aes(x = x1, xend = x2, 
                                y = y2, yend = y2) )

# save figure
ggsave(filename = "fig3C.png", path = "figures", 
       width = 25, height = 12.5, units = "cm", bg="transparent")
