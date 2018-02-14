/** \file pget.c
    \brief
    \author James Peachey, HEASARC/EUD/GSFC.
*/
#include "ape/ape_binary.h"
#include "ape/ape_error.h"

int main(int argc, char ** argv) {
  return eOK != ape_binary_pget(argc - 1, argv + 1) ? 1 : 0;
}

/*
 * $Log$
 * Revision 1.2  2006/05/19 17:44:15  peachey
 * Replace body of pget with call to ape_binary_pget.
 *
*/
