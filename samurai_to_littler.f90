program samurai_to_littler

!------------------------------------------------------------------------------!
!
!   samurai_to_littler.f90 
!   purpose - to convert samurai analyses in NetCDF format into little_r format
!    to be ingested into WRFDA program obsproc.exe
!
!   Bonnie Brown, University of Hawaii Manoa, December 2014
!
!------------------------------------------------------------------------------!
   
   USE NETCDF
   IMPLICIT NONE
   
   CHARACTER (len=*), PARAMETER :: FILE_NAME = "samurai_XYZ_analysis.nc"
   CHARACTER (len=5) :: statid = "STNID"
   CHARACTER (len=6) ::  platform = "FM-35"
   INTEGER, PARAMETER :: NLATS = 101, &
                         NLONS = 101, &
                         NLEVS = 33
   INTEGER :: ncid, sid, drid, latid, lonid, elevid, &
                pid, i, j, imax, jmax
   INTEGER :: unit_out = 20
   REAL ::  data_spd(NLATS,NLONS,NLEVS), &
            data_dir(NLATS,NLONS,NLEVS),&
            data_p(NLATS,NLONS,NLEVS),&
            pu(NLATS,NLONS,NLEVS),&
            data_lat(NLATS),&
            data_lon(NLONS),&
            data_elev(NLEVS)
   
   call check( nf90_open(FILE_NAME, NF90_NOWRITE, ncid) )
   
   call check( nf90_inq_varid(ncid,"SPDU",sid) )
   call check( nf90_inq_varid(ncid,"DIRU",drid) )
   call check( nf90_inq_varid(ncid,"latitude",latid) )
   call check( nf90_inq_varid(ncid,"longitude",lonid) )
   call check( nf90_inq_varid(ncid,"altitude",elevid) )
   call check( nf90_inq_varid(ncid,"P",pid) )

   call check( nf90_get_var(ncid,sid,data_spd) )
   call check( nf90_get_var(ncid,drid,data_dir) )
   call check( nf90_get_var(ncid,latid,data_lat) )
   call check( nf90_get_var(ncid,lonid,data_lon) )
   call check( nf90_get_var(ncid,elevid,data_elev) )
   call check( nf90_get_var(ncid,pid,data_p) )
   
   call check( nf90_close(ncid) )
   
   pu = 100 * data_p 
   data_elev = 1000 * data_elev
   
   imax = size(data_spd,1)
   jmax = size(data_spd,2)
   open( unit=unit_out, file='test_f90_samurai_littler' )
   
   
   !do i = 25,75,5
   !    do j = 25,75,5
    do i = 1,imax
        do j = 1,jmax
            call write_littler_samurai( data_elev,data_spd(i,j,:),data_dir(i,j,:), pu(i,j,:), data_lat(j), &
                        data_lon(i),0.00,'2014-07-03-12','STAID',platform,unit_out )
        enddo
    enddo
    
   
   
   CONTAINS
   
   
   subroutine write_littler_samurai(z,spd,dir,pu,lat,lon,elev,hdate,stid,instring3,iunit)
   
! Heavily based on madis_to_littler.f90 and write_littler_bogus subroutine 
   INTEGER :: iunit
   
   REAL :: lat, lon, elev
   REAL, DIMENSION(33) :: spd, dir, z, pu
   CHARACTER (len=5) :: stid
   CHARACTER *20 date_char
   CHARACTER *40 string1, string2, string3
   CHARACTER (len=40) :: string4=' '
   CHARACTER (len=*) :: instring3, hdate
   
   CHARACTER (len=84), PARAMETER :: rpt_format = ' (2f20.5 , 2a40 , ' &
                            // ' 2a40 , 1f20.5 , 5i10 , 3L10 , ' &
                            // ' 2i10 , a20 , 13( f13.5 , i7 ) ) '
   CHARACTER *22 meas_format
   CHARACTER *14 end_format
   LOGICAL :: is_sound = .TRUE.
   LOGICAL :: bogus = .FALSE.
   INTEGER :: i, kx, lm
   INTEGER :: lman 
   
   lman = size(z)

   
   meas_format = ' ( 10( f13.5 , i7 ) )'
   end_format = ' ( 3( i7 ) )'
   
   date_char(7:16) = hdate(1:4)//hdate(6:7)//hdate(9:10)//hdate(12:13)
   date_char(17:20) = '0000'
   date_char(1:6) = '      '
   
   kx = lman
   
   string1 = stid
   string2 = 'MADIS'
   string3 = trim(instring3)
   
! write header
   WRITE ( UNIT=iunit , ERR=19 , FMT=rpt_format ) &
        lat, lon, string1 , string2 , &
        string3 , string4 , elev, kx*3, 0,0,0,0, &
        is_sound,bogus,.FALSE., &
        -888888, -888888, date_char , &
        -888888.,0,-888888.,0, -888888.,0,-888888.,0, -888888.,0, &
        -88888.,0, &
        -88888.,0, -88888.,0, -88888.,0, -88888.,0, &
        -88888.,0,  -88888.,0, -88888.,0
   
   lm = 1
! write body of record
   DO WHILE ( lm <= lman )
        IF( (spd(lm).gt.-888888) .or. (dir(lm).gt.-888888) ) THEN
            WRITE( UNIT=iunit, ERR=19, FMT = meas_format ) &
                pu(lm),0, z(lm),0, -88888.,0, -88888.,0, &
                spd(lm),0, dir(lm),0, &
                -88888.,0, -88888.,0, -88888.,0, -88888.,0
        !ELSE
         !   WRITE( UNIT=iunit, ERR=19, FMT = meas_format ) &
          !      -888888.,0, z(lm),0, -88888.,0, -88888.,0, &
           !     -888888.,0, -888888.,0, &
            !    -88888.,0, -88888.,0, -88888.,0, -88888.,0
        ENDIF
        lm = lm + 1
    ENDDO
   
! Write ending of record and trailing integers
   WRITE( UNIT=iunit, ERR=19, FMT=meas_format ) &
        -777777.,0, -777777.,0, float(kx),0, &
        -88888.,0, -88888.,0, -88888.,0, &
        -88888.,0, -88888.,0, -88888.,0, &
        -88888.,0
   WRITE( UNIT=iunit, ERR=19, FMT= end_format ) kx, 0, 0
   
   return
   19 continue
        print *, 'Trouble writing sounding'
        print *, 'Mandatory stuff: ', lman
        do i = 1,lman
            write(*,*) pu(i), z(i), spd(i), dir(i)
        enddo
        
    stop 19
   
   end subroutine write_littler_samurai
   
   
   
   subroutine check(status)
        integer, intent ( in) :: status
        
        if(status /= nf90_noerr) then
            print *, trim(nf90_strerror(status))
            stop "Stopped"
        end if
    end subroutine check
    
end program samurai_to_littler
