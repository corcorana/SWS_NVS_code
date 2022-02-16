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

# import data
dat <- tryCatch( # navigate from base dir, otherwise try local
  read.csv(file.path("stats", "wsws_stimRec.csv", fsep = .Platform$file.sep), header = TRUE),
  warning = function(w)
    read.csv("wsws_stimRec.csv", header = TRUE) )

# create factors
dat <- dat %>% 
  select( !starts_with(c("RecOri", "Diff")) ) %>%
  select( !ends_with(c("Chunk2", "Chunk3")) ) %>%
  mutate(SubID = as.factor(SubID),
         Type = relevel(factor(Type), "SWS"),
         Clarity = as.ordered(Clarity),
         Cond = as.factor(Cond),
         CodeStim = as.factor(CodeStim),
         Trial = 16*(nBlock-1)+nTrial
  )


# create wide df from Chunk 1 reconstruction data only
dat.w <- dat %>% 
  select(-Rec, -Band) %>%
  pivot_wider(names_from = Rep, 
            values_from = c(Rec_Chunk1, Clarity) ) %>%
  rename(Rec1 = Rec_Chunk1_1, 
         Rec2 = Rec_Chunk1_2) %>% 
  drop_na(Rec1)


### model stimulus reconstruction scores
r0 <- lmer(Rec2 ~ Rec1 + Trial +
             (1|SubID) + (1|CodeStim), 
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

r1 <- lmer(Rec2 ~ Rec1 + Trial + Type +
             (1+Type|SubID) + (1|CodeStim), 
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

r2 <- lmer(Rec2 ~ Rec1 + Trial + Type + Cond +
             (1+Type+Cond|SubID) + (1|CodeStim),
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))
# singular

r2.1 <- lmer(Rec2 ~ Rec1 + Trial + Type + Cond +
             (1+Type|SubID) + (1|CodeStim),
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

r2.2 <- lmer(Rec2 ~ Rec1 + Trial + Type + Cond +
               (1+Cond|SubID) + (1|CodeStim),
             data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))
# singular

r3 <- lmer(Rec2 ~ Rec1 + Trial + Type * Cond +
             (1+Type*Cond|SubID) + (1|CodeStim),
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))
# singular

r3.1 <- lmer(Rec2 ~ Rec1 + Trial + Type * Cond +
             (1+Type|SubID) + (1|CodeStim),
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

r3.2 <- lmer(Rec2 ~ Rec1 + Trial + Type * Cond +
             (1+Cond|SubID) + (1|CodeStim),
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))
# singular

r4.1 <- lmer(Rec2 ~ Trial + Type * Cond * Rec1 + 
             (1+Type|SubID) + (1|CodeStim),
           data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

# compare models
anova(r0, r1, r2.1, r3.1, r4.1)

# attempt to reduce random effects complexity
r2.0 <- lmer(Rec2 ~ Rec1 + Trial + Type + Cond +
               (1|SubID) + (1|CodeStim),
             data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

r3.0 <- lmer(Rec2 ~ Rec1 + Trial + Type * Cond +
               (1|SubID) + (1|CodeStim),
             data = dat.w, REML = TRUE, control=lmerControl(optimizer="bobyqa"))

# compare models
anova(r2.1, r2.0, r3.0)

# print anova & summary table for winning model
r.wm <- r2.1
Anova(r.wm)
summary(r.wm)

# post-hoc contrasts for winning model
pairs(emmeans(r.wm, ~Cond))



### introduce stimulus reconstruction score into clarity model

# set winning clarity model (c3.2 from wsws_stimrec.R) as null
cr0 <- clmm(Clarity_2 ~ Clarity_1 + Trial + Type * Cond +
              (1+Cond|SubID) + (1|CodeStim),      
            data = dat.w)

cr1 <- clmm(Clarity_2 ~ Clarity_1 + Trial + Type * Cond + Rec2 + 
              (1+Cond|SubID) + (1|CodeStim),      
            data = dat.w)

cr2 <- clmm(Clarity_2 ~ Clarity_1 + Trial + Type * Cond * Rec2 + 
              (1+Cond|SubID) + (1|CodeStim),
            data = dat.w)

# compare models
anova(cr0, cr1, cr2)

# attempt to maximise random effects on Subject ID
cr2.1 <- clmm(Clarity_2 ~ Clarity_1 + Trial + Type * Cond * Rec2 + 
                (1+Cond+Rec2|SubID) + (1|CodeStim),
              data = dat.w)

cr2.2 <- clmm(Clarity_2 ~ Clarity_1 + Trial + Type * Cond * Rec2 + 
                (1+Cond*Rec2|SubID) + (1|CodeStim),
              data = dat.w)

cr2.3 <- clmm(Clarity_2 ~ Clarity_1 + Trial + Type * Cond * Rec2 + 
                (1+Cond*Rec2+Type|SubID) + (1|CodeStim),
              data = dat.w)

cr2.4 <- clmm(Clarity_2 ~ Clarity_1 + Trial + Type * Cond * Rec2 + 
                (1+Cond*Rec2*Type|SubID) + (1|CodeStim),
              data = dat.w)

# compare models
anova(cr2, cr2.1, cr2.2, cr2.3, cr2.4)

# print anova & summary table for winning model
cr.wm <- cr2
Anova.clmm(cr.wm, type=2)
summary(cr.wm)

# post-hoc contrasts for winning model
pairs(emtrends(cr.wm, ~Cond|Type, var = "Rec2"))
contrast(emtrends(cr.wm, ~Cond*Type, var = "Rec2"), interaction = "pairwise", adjust="sidak")

# plot interaction by Type
emmip(cr.wm, Cond~Rec2|Type, at = list(Rec2 = c(-.5, .5)))

