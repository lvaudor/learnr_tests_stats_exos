to_bins=function(mydf,var,qmin,qmax,Nbins, by_frame=FALSE){
  count_elems_in_bins=function(dat,var="X"){
    result=bind_cols(id=1:(Nbins-1),
                     Xmin=seq(qmin,qmax,length.out=Nbins)[1:(Nbins-1)],
                     Xmax=seq(qmin,qmax,length.out=Nbins)[2:Nbins]) %>% 
      dplyr::mutate(Y=purrr::map2_int(.x=Xmin,.y=Xmax,~length(which(dat[[var]]>.x & dat[[var]]<=.y)))) %>% 
      dplyr::mutate(Y=Y/max(Y)) %>%  
      tidyr::pivot_longer(all_of(c("Xmin","Xmax")), names_to="boundary",values_to="X")
    return(result)
  }
  if(by_frame==TRUE){
  result=mydf %>% 
    group_by(frame) %>% 
    tidyr::nest() %>% 
    mutate(Y=map(.x=data, ~count_elems_in_bins(.x))) %>% 
    tidyr::unnest(cols=c("Y"))
  }
  if(by_frame==FALSE){
    result=mydf %>% 
      count_elems_in_bins(var="Xbar")
  }
  return(result)
}
repeat_identical=function(mydf,frame){
  mydf=map(as.list(frame),
           ~bind_cols(frame=rep(.,nrow(mydf)),
                      mydf)) %>% 
    bind_rows()
  return(mydf)
}


distribution_of_mean=function(N,
                              mu,
                              sigma,
                              nIter=300,
                              nImages=30,
                              model="norm",
                              Nbins_X=20,
                              Nbins_moy=40,
                              show=c(TRUE,TRUE,TRUE,TRUE)){
  dfun=get(paste0("d",model))
  qfun=get(paste0("q",model))
  rfun=get(paste0("r",model))
  qmin=qfun(0.01,mu,sigma)
  qmax=qfun(0.99,mu,sigma)
  xd=seq(qmin,qmax,length.out=300)
  #####
  dfX=dplyr::tibble(frame=1:nIter) %>%
    dplyr::group_by(frame) %>% 
    tidyr::nest() %>% 
    dplyr::mutate(data=map(frame,~tibble(X=rfun(N,mu,sigma)))) %>% 
    tidyr::unnest(cols=c("data")) %>% 
    dplyr::group_by(frame) %>% 
    dplyr::mutate(Xbar=mean(X)) %>% 
    dplyr::ungroup()
  #####
  dfXplot=dfX %>% 
    dplyr::filter(frame<=nImages) %>% 
    to_bins(var="X",qmin=qmin,qmax=qmax,Nbins=Nbins_X, by_frame=TRUE) 
  #####  
  dfXbar=dfX %>% 
    dplyr::select(frame,Xbar) %>% 
    unique()  
    
  dfXTheo=tibble::tibble(xd=xd,
                 yd=dfun(xd,mu,sigma)) %>% 
    repeat_identical(frame=1:nImages) %>% 
    dplyr::mutate(yd=yd/max(yd))
  #######
  dfX=dplyr::filter(dfX,frame<=nImages)
  xlarge=rfun(100000,mu,sigma)
  meantheo=mean(xlarge)
  sdtheo=sd(xlarge)
  dfXbarTheo=tibble::tibble(xd=xd,
                    yd=dnorm(xd,meantheo,sdtheo/sqrt(N))) %>% 
   # repeat_identical(frame=1:nImages) %>% 
    dplyr::mutate(yd=yd/max(yd))
  dfXbar=to_bins(dfXbar,var="Xbar", qmin=qmin, qmax=qmax, Nbins=Nbins_moy, by_frame=FALSE)
  #########
  panim=ggplot2::ggplot(dfX,ggplot2::aes(x=X))+
    ggplot2::scale_x_continuous(limits=c(qmin,qmax))+
    ggplot2::scale_y_continuous(labels=NULL)+
    ggplot2::ggtitle(bquote(paste(X," de loi ",.(model)(mu==.(mu),sigma==.(sigma))," avec ",N==.(N))))
  # Distrib théorique de X
  if(show[1]){
    panim=panim+
      ggplot2::geom_ribbon(data=dfXTheo,
                  aes(x=xd,ymin=0,ymax=yd),
                  fill="forestgreen", alpha=0.25)
  }
  # Distrib observée de X
  if(show[2]){
      panim=panim+
        ggplot2::geom_ribbon(data=dfXplot,
                             ggplot2::aes(x=X,ymax=Y,ymin=0),
                    col="forestgreen", alpha=0.25)+
        ggplot2::geom_vline(aes(xintercept=Xbar), col="#A03090")
  }
  # Distrib théorique des moyennes
  if(show[3]){
    panim=panim+
      ggplot2::geom_ribbon(data=dfXbarTheo,
                  aes(x=xd,ymin=0,ymax=yd),
                  fill="#A03090", alpha=0.25)
  }
  # Distrib observée des moyennes
  if(show[4]){
    panim=panim+
      geom_ribbon(data=dfXbar,
                  aes(x=X,ymax=Y, ymin=0),
                  col="#A03090", alpha=0.25
      )
  }
  anim=panim
  if(show[2]){
      anim=panim+transition_states(frame,transition_length=1,state_length=1)
    }
  return(anim)
}

