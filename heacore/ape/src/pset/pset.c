/** \file pset.c
    \brief
    \author James Peachey, HEASARC/EUD/GSFC.
*/
#include "ape/ape_binary.h"
#include "ape/ape_error.h"

int main(int argc, char ** argv) {
  return eOK != ape_binary_pset(argc - 1, argv + 1) ? 1 : 0;
}

/*
 * $Log$
 */
