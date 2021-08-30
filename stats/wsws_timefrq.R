library(tidyverse)
library(lme4)
library(car)
library(emmeans)
library(performance)
library(ordinal)
library(RVAideMemoire)

# global settings
options(contrasts = c("contr.sum", "contr.poly"))

theme_set(theme_bw())
font_theme <- theme(
  axis.title.x = element_text(size = 20, face="bold"),
  axis.title.y = element_text(size = 20, face="bold"),
  axis.text.x = element_text(size = 20, face="bold"),
  axis.text.y = element_text(size = 20, face="bold"),
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


## wrangling
data <- read.csv("wsws_timefrq.csv", header=TRUE)

# trim empty rows at foot of df, recode NaNs to NAs
data <- data[!is.nan(data$subj_id),]
data[data=="NaN"] <- NA

# create factors
data <- data %>% 
  mutate(subj_id = as.factor(subj_id),
         stim = as.factor(stim),
         cond = as.factor(cond),
         chan_id = as.factor(chan),
         freq = as.factor(freq),
         clarity1 = as.ordered(clarity1),
         clarity2 = as.ordered(clarity2)
  ) %>%
  droplevels()

levels(data$stim) <- list( SWS="1", NVS="2")
levels(data$cond) <- list( pos="1", neg="2", zero="3" )
levels(data$freq) <- list( Delta = "1", Theta="2", Alpha="3", Beta="4" )


### clarity ratings ###
clar <- data %>%
  filter(chan == 1 & freq == "Delta") %>%
  select(-freq, -chan, -chan_id) %>%
  drop_na(clarity1)

c1 <- clmm(clarity2 ~ clarity1 + stim + 
             (1+stim|subj_id) + (1|item_id), 
           data = clar)	

c2 <- clmm(clarity2 ~ clarity1 + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id),
           data = clar)	

c3 <- clmm(clarity2 ~ clarity1 + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id), 
           data = clar)	

# compare models
anova(c1, c2, c3)

# anova table for winning model
Anova.clmm(c2, type=2)

# contrasts for winning model
pairs(emmeans(c2, ~stim))
pairs(emmeans(c2, ~cond))


### spectral power ###
delta <- filter(data, freq=="Delta")
theta <- filter(data, freq=="Theta")
alpha <- filter(data, freq=="Alpha")
beta <- filter(data, freq=="Beta")


## delta-band
d1 <- lmer(logpow2 ~ logpow1 + clarity1 + stim + 
             (1+stim|subj_id) + (1|item_id) + (1|chan_id),
           data=delta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

d2 <- lmer(logpow2 ~ logpow1 + clarity1 + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
           data=delta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

d3 <- lmer(logpow2 ~ logpow1 + clarity1 + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
           data=delta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(d1, d2, d3)

# refit winning model with REML
d3.r <- lmer(logpow2 ~ logpow1 + clarity1 + stim * cond + 
               (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
             data=delta, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

# anova table
Anova(d3.r)

# contrasts
pairs(emmeans(d3.r, ~stim))
pairs(emmeans(d3.r, ~cond))


## theta-band
t1 <- lmer(logpow2 ~ logpow1 + clarity1 + stim + 
             (1+stim|subj_id) + (1|item_id) + (1|chan_id),
           data=theta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

t2 <- lmer(logpow2 ~ logpow1 + clarity1 + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
           data=theta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

t3 <- lmer(logpow2 ~ logpow1 + clarity1 + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
           data=theta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(t1, t2, t3)

# refit winning model with REML
t3.r <- lmer(logpow2 ~ logpow1 + clarity1 + stim * cond + 
               (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
             data=theta, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

# anova table
Anova(t3.r)

# contrasts
pairs(emmeans(t3.r, ~stim))
pairs(emmeans(t3.r, ~cond))


## alpha-band
a1 <- lmer(logpow2 ~ logpow1 + clarity1 + stim + 
             (1+stim|subj_id) + (1|item_id) + (1|chan_id),
           data=alpha, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

a2 <- lmer(logpow2 ~ logpow1 + clarity1 + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
           data=alpha, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

a3 <- lmer(logpow2 ~ logpow1 + clarity1 + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
           data=alpha, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(a1, a2, a3)

# refit winning model with REML
a3.r <- lmer(logpow2 ~ logpow1 + clarity1 + stim * cond + 
               (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
             data=alpha, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

# anova table
Anova(a3.r)

# contrasts
pairs(emmeans(a3.r, ~stim))
pairs(emmeans(a3.r, ~cond))

## beta-band
b1 <- lmer(logpow2 ~ logpow1 + clarity1 + stim + 
             (1+stim|subj_id) + (1|item_id) + (1|chan_id),
           data=beta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

b2 <- lmer(logpow2 ~ logpow1 + clarity1 + stim + cond + 
             (1+stim+cond|subj_id) + (1|item_id) + (1|chan_id),
           data=beta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

b3 <- lmer(logpow2 ~ logpow1 + clarity1 + stim * cond + 
             (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
           data=beta, REML = FALSE, control=lmerControl(optimizer="bobyqa") )

# compare models
anova(b1, b2, b3)

# refit winning model with REML
b3.r <- lmer(logpow2 ~ logpow1 + clarity1 + stim * cond + 
               (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
             data=beta, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

# anova table
Anova(b3.r)

# contrasts
pairs(emmeans(b3.r, ~stim))
pairs(emmeans(b3.r, ~cond))


### plot condition effect (marginalise over stim)

## refit to mean-centred data 
mc <- data %>%
  group_by(subj_id, freq) %>%
  summarise(muPow = mean(logpow2, na.rm=T), sdPow = sd(logpow2, na.rm=T)) %>%
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

d3.mc <- lmer(logpow2.mc ~ logpow1 + clarity1 + stim*cond + 
                (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
              data=delta.mc, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

t3.mc <- lmer(logpow2.mc ~ logpow1 + clarity1 +  stim*cond + 
                (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
              data=theta.mc, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

a3.mc <- lmer(logpow2.mc ~ logpow1 + clarity1 + stim*cond + 
                (1+stim*cond|subj_id) + (1|item_id) + (1|chan_id),
              data=alpha.mc, REML = TRUE, control=lmerControl(optimizer="bobyqa") )

b3.mc <- lmer(logpow2.mc ~ logpow1 + clarity1 + stim*cond +
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


### plot Fig 3C -- only display significant condition effects (drop Beta model)
emms <- rbind(emmd, emmt, emma)
m3 <- m2 %>% filter(freq!="Beta") %>% droplevels()


# prepare annotations
anno <- data.frame(x1 = c(2, 1, 1, 1, 2, 1), 
                   x2 = c(3, 3, 2, 3, 3, 3), 
                   y1 = c(.085, .120, .085, .120, .085, .120), 
                   y2 = c(.095, .130, .095, .130, .095, .130), 
                   xstar = c(2.5, 2, 1.5, 2, 2.5, 2), 
                   ystar = c(.1, .135, .1, .135, .1, .135),
                   lab = c("***", "*", "***", "*", "***", '***'),
                   freq = c("Delta", "Delta", "Theta", "Theta", "Alpha", "Alpha") )


# plot facet grid
ggplot() +
  geom_line(dat = m3,
            aes(x = ji, y = l2, group = subj_id), size=.7, alpha = .3 ) +
  geom_point(dat = m3,
             aes(x = ji, y = l2, fill = cond), size = 3, alpha = .3, stroke = 1.5, shape=21) +
  scale_y_continuous(position = "right", name = "Power (a.u.)", 
                     limits = c(-.12, .14), breaks = c(-.1, 0, .1), labels = c("-.1", "0", ".1") ) +
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
        axis.text.x = element_text(color=colCond), 
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
ggsave(filename = "fig3C.png", path = file.path("..", "figures", fsep = .Platform$file.sep), 
       width = 20, height = 11, units = "cm", bg="transparent")
