#!/usr/sbin/dtrace -s
#pragma D option quiet

/* Author: Kirill.Davydychev@Nexenta.com */
/* Copyright 2012, Nexenta Systems, Inc. All rights reserved. */

dmu_buf_hold_array_by_dnode:entry
/args[0]->dn_objset->os_dsl_dataset && args[3]/ /* Reads */
{
        this->ds = stringof(args[0]->dn_objset->os_dsl_dataset->ds_dir->dd_myname);
        this->parent = stringof(args[0]->dn_objset->os_dsl_dataset->ds_dir->dd_parent->dd_myname);
        this->path = strjoin(strjoin(this->parent,"/"),this->ds);
        @ior[this->path] = count();
        @tpr[this->path] = sum(args[2]);
}

dmu_buf_hold_array_by_dnode:entry
/args[0]->dn_objset->os_dsl_dataset && !args[3]/ /* Writes */
{
        this->ds = stringof(args[0]->dn_objset->os_dsl_dataset->ds_dir->dd_myname);
        this->parent = stringof(args[0]->dn_objset->os_dsl_dataset->ds_dir->dd_parent->dd_myname);
        this->path = strjoin(strjoin(this->parent,"/"),this->ds);
        @iow[this->path] = count();
        @tpw[this->path] = sum(args[2]);
}

tick-1sec
{
        printf("                                          operations      bandwidth\n");
        printf("Dataset                                  read   write  read       write\n");
        printf("                                         ------ ------ ---------- ----------\n");
        printa("%-40s %@-6d %@-6d %@-10d %@-10d\n",@ior,@iow,@tpr,@tpw);
        trunc(@ior); trunc(@tpr); trunc(@iow); trunc(@tpw);
     /* clear(@ior); clear(@tpr); clear(@iow); clear(@tpw); */
     /* TODO: Make script more interactive. Above, uncomment clear() and comment trunc() line in order to change
        truncate behavior */
}
