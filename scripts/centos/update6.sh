#!/bin/bash
yum clean dbcache
rpm --rebuilddb
yum makecache
yum update -y
