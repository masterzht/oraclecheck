Select namespace, gets, gethits, gethitratio, pins, pinhits, pinhitratio, reloads, invalidations from v$librarycache;

Select KSMLRCOM, KSMLRHON, KSMLRNUM, KSMLRSIZ from x$ksmlru where KSMLRSIZ > 5000;
