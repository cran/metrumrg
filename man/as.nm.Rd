\name{as.nm}
\alias{nm}
\alias{as.nm}
\alias{as.nm.default}
\alias{as.nm.data.frame}
%\alias{merge.nm}
\alias{read.nm}
\alias{write.nm}

\title{Create and Manipulate nm Objects}
\description{
Objects of class \dfn{nm} are intended to support analysis using the software
NONMEM ((c), Icon Development Solutions). \code{nm} gives a zero-row data.frame with
suitable columns and column classes (essentially, a template for dataset construction).  
\code{as.nm} and \code{as.nm.data.frame} construct an
nm object from an existing object.  The read and write methods are wrappers
for \file{.csv} equivalents. \code{read.nm} reconstitutes classes for flags, 
DATETIME, and C.  

%\code{merge.nm} coerces its result using \code{as.nm}, guaranteeing
%a consistent left hand object when using \code{Ops.keyed}.
}
\usage{
nm()
\method{as.nm}{data.frame}(x, ...)
read.nm(x,na.strings='.',as.is=TRUE,key=c('SUBJ','TIME','SEQ'),flags=character(0),...)
write.nm(x, file, na = '.', row.names = FALSE, quote = FALSE, ...)
}
\arguments{
  \item{x}{data.frame or nm}
  \item{na.strings}{passed to \code{read.csv}}
  \item{as.is}{passed to \code{read.csv}}
  \item{key}{passed to \code{as.keyed}}
  \item{flags}{character vector naming colums to convert using \code{as.flag}}
  \item{\dots}{extra arguments, ignored or passed to \code{write.csv}}
  \item{file}{passed to \code{write.csv}}
  \item{na}{passed to \code{write.csv}}
  \item{row.names}{passed to \code{write.csv}}
  \item{quote}{passed to \code{write.csv}}  
}

\details{
\code{as.nm.data.frame} is the principal method that creates an nm classification.  It 
alone enforces all qualities of class nm.  \code{read.nm} is the only other function
that creates an nm classification; use with caution, as it does not enforce all qualities.

Just before \code{as.nm.data.frame} returns, it calls \code{as.nm} on each of 
its columns: a non-operation (\code{as.nm.default}) unless the user supplies specialized
classes and methods. Column-specific methods may make use of the passed argument
\code{data}, which contains the data set itself. Any enforced or conditional outputs
(see column summary) have the column name as the first member of the class vector.

\itemize{
  \item \code{SUBJ} must be present and defined, even for commented records. ID is (re)calculated as \code{as.numeric(factor(SUBJ))}.
  \item \code{C} (class:  comment) will be created if not present.
  \item \code{NA} \code{C} will be imputed \code{FALSE}.
  \item Every active (non-commented) source record should define exactly one of \code{HOUR} or \code{DATETIME}.
  \item \code{HOUR} is taken to represent relative accumulation of hours from arbitrary origin.
  \item \code{DATETIME} is understood as seconds, coercible to \code{mDateTime}.
  \item \code{TIME} is calculated from either \code{HOUR} or \code{DATETIME}.
  \item Definition (or not) of \code{HOUR} vs. \code{DATETIME} should be constant within subject (for active records).
  \item \code{SEQ} (class \code{flag}) will be created if not present.
  \item \code{nm} will be keyed on \code{SUBJ}, \code{TIME}, and \code{SEQ}. \code{SEQ} determines sort order for rows with matching \code{TIME}.
  \item Result will be sorted.
  \item \code{TIME} will be relativized to earliest extant value, incl. those in comments.
  \item \code{TAFD} (time after first non-commented dose), \code{TAD} (time since most recent non-commented dose), and \code{LDOS} (amount of most recent non-commented dose) will be calculated if \code{AMT} is present. \code{TAD} and \code{LDOS} are very literal:  they return NA if no dose has been given yet, and will "remember" the time and amount of the most recent dose whether or not it is still conceptually relevant, given study design.  If two doses are given at the same time, say in different compartments, LDOS reflects the first AMT with respect to sort order.
  \item \code{TAD} will consider \code{ADDL} and \code{II} if present.
  \item \code{NA} flags will be imputed as zero.
  \item \code{MDV} (missing dependent value) will be calculated if \code{DV} is present, preserving non-NA MDV, if present.
  \item resulting column order will lead with \code{C} followed by key columns.
}

  Column summary:
\itemize{
  \item required inputs: SUBJ; HOUR or DATETIME
  \item optional inputs: AMT, ADDL, II, DV 
  \item enforced outputs: SUBJ, ID, C, TIME, SEQ
  \item conditional outputs: TAFD, TAD, LDOS, MDV
}
}
\value{
\code{write.nm} is used for side effects. Others return an object with class 
\code{c('nm','keyed','data.frame')}.
}
\references{\url{http://metrumrg.googlecode.com}}
\author{Tim Bergsma}
\note{
	Assembly chains, such as \code{nm() + dose + samp | demo}, are no longer
	supported.  \code{as.moot} and \code{as.rigged} are deprecated.

}
\seealso{
	\itemize{
		\item \code{\link{summary.nm}}
		\item \code{\link{Ops.keyed}}
	}
}
\examples{
\dontrun{metrumrgURL('example/project/script/assemble.pdf')}

dose <- data.frame( 
	SUBJ = rep(letters[1:3], each = 2), 
	HOUR = rep(c(0,20),3), 
	AMT = rep(c(40,60,80), each = 2) 
) 
dose <- as.keyed(dose,key=c('SUBJ','HOUR'))
samp <- data.frame( 
	SUBJ = rep(letters[1:3], each = 4), 
	HOUR = rep(c(0,10,20,30),3), 
	DV = signif(rnorm(12),2) + 2 
) 
samp <- as.keyed(samp,key=c('SUBJ','HOUR'))
demo <- data.frame( 
	SUBJ = letters[2:5], 
	RACE = c('asian','white','black','other'), 
	SEX = c('female','male','female','male'), 
	WT = c(75, 70, 73, 68) 
)
demo <- as.keyed(demo,key=c('SUBJ'))
meds <- as.keyed(
	data.frame(
		SUBJ=c('a','c'),
		HOUR=c(0,15),
		STOP=c(10,25),
		C3A4=as.flag(c(1,1))
	),
	key=c('SUBJ','HOUR')
)

nm()
#nm() + dose
as.nm(dose)
as.nm(dose + samp)
as.nm(dose + samp | demo) #as.nm executes once
#nm() + dose + samp | demo #deprecated

meds
long <- deranged(meds,start='HOUR',stop='STOP')
long$EVID <- 2
as.nm( dose + samp + long)
#nm() + dose + samp + long - as.moot() # deprecated
#nm() + dose + samp + as.rigged(n=10) # deprecated
data <- as.nm( aug(dose,EVID=1, SEQ=1) + aug(samp,EVID=0, SEQ=0) | demo)
summary(data,by=c('EVID','SEQ'))
\dontrun{index(data)}
}
\keyword{manip}

