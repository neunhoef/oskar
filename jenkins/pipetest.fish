#!/usr/bin/env fish
env
function term -s TERM ; echo %self got term ; echo %self got term >>$HOME/fishpids ; end
echo Los %self
echo Los %self >>$HOME/fishpids
sleep 180
echo Fertig %self
echo Fertig %self >> $HOME/fishpids

