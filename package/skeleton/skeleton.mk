################################################################################
#
# skeleton
#
################################################################################

# source included in buildroot
SKELETON_SOURCE =

# The skeleton can't depend on the toolchain, since all packages depends on the
# skeleton and the toolchain is a target package, as is skeleton.
# Hence, skeleton would depends on the toolchain and the toolchain would depend
# on skeleton.
SKELETON_ADD_TOOLCHAIN_DEPENDENCY = NO

# The skeleton also handles the merged /usr case in the sysroot
SKELETON_INSTALL_STAGING = YES

ifeq ($(BR2_ROOTFS_SKELETON_CUSTOM),y)

SKELETON_PATH = $(call qstrip,$(BR2_ROOTFS_SKELETON_CUSTOM_PATH))

ifeq ($(BR2_ROOTFS_MERGED_USR),y)

# Ensure the user has prepared a merged /usr.
#
# Extract the inode numbers for all of those directories. In case any is
# a symlink, we want to get the inode of the pointed-to directory, so we
# append '/.' to be sure we get the target directory. Since the symlinks
# can be anyway (/bin -> /usr/bin or /usr/bin -> /bin), we do that for
# all of them.
#
SKELETON_LIB_INODE = $(shell stat -c '%i' $(SKELETON_PATH)/lib/.)
SKELETON_BIN_INODE = $(shell stat -c '%i' $(SKELETON_PATH)/bin/.)
SKELETON_SBIN_INODE = $(shell stat -c '%i' $(SKELETON_PATH)/sbin/.)
SKELETON_USR_LIB_INODE = $(shell stat -c '%i' $(SKELETON_PATH)/usr/lib/.)
SKELETON_USR_BIN_INODE = $(shell stat -c '%i' $(SKELETON_PATH)/usr/bin/.)
SKELETON_USR_SBIN_INODE = $(shell stat -c '%i' $(SKELETON_PATH)/usr/sbin/.)

ifneq ($(SKELETON_LIB_INODE),$(SKELETON_USR_LIB_INODE))
SKELETON_CUSTOM_NOT_MERGED_USR += /lib
endif
ifneq ($(SKELETON_BIN_INODE),$(SKELETON_USR_BIN_INODE))
SKELETON_CUSTOM_NOT_MERGED_USR += /bin
endif
ifneq ($(SKELETON_SBIN_INODE),$(SKELETON_USR_SBIN_INODE))
SKELETON_CUSTOM_NOT_MERGED_USR += /sbin
endif

ifneq ($(SKELETON_CUSTOM_NOT_MERGED_USR),)
$(error The custom skeleton in $(SKELETON_PATH) is not \
	using a merged /usr for the following directories: \
	$(SKELETON_CUSTOM_NOT_MERGED_USR))
endif

endif # merged /usr

else # ! custom skeleton

SKELETON_PATH = system/skeleton

endif # ! custom skeleton

# This function handles the merged or non-merged /usr cases
ifeq ($(BR2_ROOTFS_MERGED_USR),y)
define SKELETON_USR_SYMLINKS_OR_DIRS
	ln -snf usr/bin $(1)/bin
	ln -snf usr/sbin $(1)/sbin
	ln -snf usr/lib $(1)/lib
endef
else
define SKELETON_USR_SYMLINKS_OR_DIRS
	$(INSTALL) -d -m 0755 $(1)/bin
	$(INSTALL) -d -m 0755 $(1)/sbin
	$(INSTALL) -d -m 0755 $(1)/lib
endef
endif

# We make a symlink lib32->lib or lib64->lib as appropriate
# MIPS64/n32 requires lib32 even though it's a 64-bit arch.
ifeq ($(BR2_ARCH_IS_64)$(BR2_MIPS_NABI32),y)
SKELETON_LIB_SYMLINK = lib64
else
SKELETON_LIB_SYMLINK = lib32
endif

define SKELETON_INSTALL_TARGET_CMDS
	rsync -a --ignore-times $(RSYNC_VCS_EXCLUSIONS) \
		--chmod=u=rwX,go=rX --exclude .empty --exclude '*~' \
		$(SKELETON_PATH)/ $(TARGET_DIR)/
	$(call SKELETON_USR_SYMLINKS_OR_DIRS,$(TARGET_DIR))
	ln -snf lib $(TARGET_DIR)/$(SKELETON_LIB_SYMLINK)
	ln -snf lib $(TARGET_DIR)/usr/$(SKELETON_LIB_SYMLINK)
	$(INSTALL) -m 0644 support/misc/target-dir-warning.txt \
		$(TARGET_DIR_WARNING_FILE)
endef

# For the staging dir, we don't really care about /bin and /sbin.
# But for consistency with the target dir, and to simplify the code,
# we still handle them for the merged or non-merged /usr cases.
# Since the toolchain is not yet available, the staging is not yet
# populated, so we need to create the directories in /usr
define SKELETON_INSTALL_STAGING_CMDS
	$(INSTALL) -d -m 0755 $(STAGING_DIR)/usr/lib
	$(INSTALL) -d -m 0755 $(STAGING_DIR)/usr/bin
	$(INSTALL) -d -m 0755 $(STAGING_DIR)/usr/sbin
	$(INSTALL) -d -m 0755 $(STAGING_DIR)/usr/include
	$(call SKELETON_USR_SYMLINKS_OR_DIRS,$(STAGING_DIR))
	ln -snf lib $(STAGING_DIR)/$(SKELETON_LIB_SYMLINK)
	ln -snf lib $(STAGING_DIR)/usr/$(SKELETON_LIB_SYMLINK)
endef

SKELETON_TARGET_GENERIC_TIMESERVER = $(call qstrip,$(BR2_TARGET_GENERIC_TIMESERVER))
SKELETON_TARGET_GENERIC_HOSTNAME = $(call qstrip,$(BR2_TARGET_GENERIC_HOSTNAME))
SKELETON_TARGET_GENERIC_ISSUE = $(call qstrip,$(BR2_TARGET_GENERIC_ISSUE))
SKELETON_TARGET_GENERIC_ROOT_PASSWD = $(call qstrip,$(BR2_TARGET_GENERIC_ROOT_PASSWD))
SKELETON_TARGET_GENERIC_PASSWD_METHOD = $(call qstrip,$(BR2_TARGET_GENERIC_PASSWD_METHOD))
SKELETON_TARGET_GENERIC_BIN_SH = $(call qstrip,$(BR2_SYSTEM_BIN_SH))
SKELETON_TARGET_GENERIC_GETTY_PORT = $(call qstrip,$(BR2_TARGET_GENERIC_GETTY_PORT))
SKELETON_TARGET_GENERIC_GETTY_BAUDRATE = $(call qstrip,$(BR2_TARGET_GENERIC_GETTY_BAUDRATE))
SKELETON_TARGET_GENERIC_GETTY_TERM = $(call qstrip,$(BR2_TARGET_GENERIC_GETTY_TERM))
SKELETON_TARGET_GENERIC_GETTY_OPTIONS = $(call qstrip,$(BR2_TARGET_GENERIC_GETTY_OPTIONS))

ifneq ($(SKELETON_TARGET_GENERIC_TIMESERVER),)
define SYSTEM_TIMESERVER
	$(INSTALL) -m 0755 -D $(SKELETON_PKGDIR)/rdate \
		$(TARGET_DIR)/etc/network/if-up.d/rdate
	$(SED) "s/TIMESERVERS/$(SKELETON_TARGET_GENERIC_TIMESERVER)/" \
		$(TARGET_DIR)/etc/network/if-up.d/rdate
endef
TARGET_FINALIZE_HOOKS += SYSTEM_TIMESERVER
endif

ifneq ($(SKELETON_TARGET_GENERIC_HOSTNAME),)
define SYSTEM_HOSTNAME
	mkdir -p $(TARGET_DIR)/etc
	echo "$(SKELETON_TARGET_GENERIC_HOSTNAME)" > $(TARGET_DIR)/etc/hostname
	$(SED) '$$a \127.0.1.1\t$(SKELETON_TARGET_GENERIC_HOSTNAME)' \
		-e '/^127.0.1.1/d' $(TARGET_DIR)/etc/hosts
endef
TARGET_FINALIZE_HOOKS += SYSTEM_HOSTNAME
endif

ifeq ($(BR2_TARGET_GENERIC_CABUNDLE),y)
define SYSTEM_CABUDLE
	mkdir -p $(TARGET_DIR)/etc/ssl/certs/
	$(WGET) -O $(TARGET_DIR)/etc/ssl/certs/ca-certificates.crt http://curl.haxx.se/ca/cacert.pem
endef
TARGET_FINALIZE_HOOKS += SYSTEM_CABUDLE
endif

ifneq ($(SKELETON_TARGET_GENERIC_ISSUE),)
define SYSTEM_ISSUE
	mkdir -p $(TARGET_DIR)/etc
	echo "$(SKELETON_TARGET_GENERIC_ISSUE)" > $(TARGET_DIR)/etc/issue
endef
TARGET_FINALIZE_HOOKS += SYSTEM_ISSUE
endif

define SET_NETWORK_LOCALHOST
	( \
		echo "# interface file auto-generated by buildroot"; \
		echo ;                                               \
		echo "auto lo";                                      \
		echo "iface lo inet loopback";                       \
	) > $(TARGET_DIR)/etc/network/interfaces
endef

NETWORK_DHCP_IFACE = $(call qstrip,$(BR2_SYSTEM_DHCP))

ifneq ($(NETWORK_DHCP_IFACE),)
ifeq ($(BR2_PACKAGE_WPA_SUPPLICANT),y)
IFACE_WPA_SUPPLICANT = \
	[[ "$(NETWORK_DHCP_IFACE)" == "wlan"* ]] && \
		echo "	pre-up /etc/network/wlan_check up $(NETWORK_DHCP_IFACE) \"$(BR2_PACKAGE_WPA_SUPPLICANT_OPTIONS)\"" && \
		echo "	pre-down /etc/network/wlan_check down $(NETWORK_DHCP_IFACE)";
define INSTALL_WPA_CHECK
	$(INSTALL) -m 0755 -D $(SKELETON_PKGDIR)/wlan_check \
		$(TARGET_DIR)/etc/network/wlan_check
endef
endif
define SET_NETWORK_DHCP
	( \
		echo ;                                               \
		echo "auto $(NETWORK_DHCP_IFACE)";                   \
		echo "iface $(NETWORK_DHCP_IFACE) inet dhcp";        \
		echo "	pre-up /etc/network/nfs_check";              \
		$(IFACE_WPA_SUPPLICANT)                              \
		echo "	wait-delay 15";                              \
	) >> $(TARGET_DIR)/etc/network/interfaces
	$(INSTALL) -m 0755 -D $(SKELETON_PKGDIR)/nfs_check \
		$(TARGET_DIR)/etc/network/nfs_check
	$(INSTALL_WPA_CHECK)
endef
endif

define SET_NETWORK
	mkdir -p $(TARGET_DIR)/etc/network/
	$(SET_NETWORK_LOCALHOST)
	$(SET_NETWORK_DHCP)
endef

TARGET_FINALIZE_HOOKS += SET_NETWORK

# The TARGET_FINALIZE_HOOKS must be sourced only if the users choose to use the
# default skeleton.
ifeq ($(BR2_ROOTFS_SKELETON_DEFAULT),y)

ifeq ($(BR2_TARGET_ENABLE_ROOT_LOGIN),y)
ifeq ($(SKELETON_TARGET_GENERIC_ROOT_PASSWD),)
SYSTEM_ROOT_PASSWORD =
else ifneq ($(filter $$1$$% $$5$$% $$6$$%,$(SKELETON_TARGET_GENERIC_ROOT_PASSWD)),)
SYSTEM_ROOT_PASSWORD = '$(SKELETON_TARGET_GENERIC_ROOT_PASSWD)'
else
SKELETON_DEPENDENCIES += host-mkpasswd
# This variable will only be evaluated in the finalize stage, so we can
# be sure that host-mkpasswd will have already been built by that time.
SYSTEM_ROOT_PASSWORD = "`$(MKPASSWD) -m "$(SKELETON_TARGET_GENERIC_PASSWD_METHOD)" "$(SKELETON_TARGET_GENERIC_ROOT_PASSWD)"`"
endif
else # !BR2_TARGET_ENABLE_ROOT_LOGIN
SYSTEM_ROOT_PASSWORD = "*"
endif

define SKELETON_SYSTEM_SET_ROOT_PASSWD
	$(SED) s,^root:[^:]*:,root:$(SYSTEM_ROOT_PASSWORD):, $(TARGET_DIR)/etc/shadow
endef
TARGET_FINALIZE_HOOKS += SKELETON_SYSTEM_SET_ROOT_PASSWD

ifeq ($(BR2_SYSTEM_BIN_SH_NONE),y)
define SKELETON_SYSTEM_BIN_SH
	rm -f $(TARGET_DIR)/bin/sh
endef
else
define SKELETON_SYSTEM_BIN_SH
	ln -sf $(SKELETON_TARGET_GENERIC_BIN_SH) $(TARGET_DIR)/bin/sh
endef
endif
TARGET_FINALIZE_HOOKS += SKELETON_SYSTEM_BIN_SH

ifeq ($(BR2_TARGET_GENERIC_GETTY),y)
ifeq ($(BR2_INIT_SYSV),y)
# In sysvinit inittab, the "id" must not be longer than 4 bytes, so we
# skip the "tty" part and keep only the remaining.
define SKELETON_SYSTEM_GETTY
	$(SED) '/# GENERIC_SERIAL$$/s~^.*#~$(shell echo $(SKELETON_TARGET_GENERIC_GETTY_PORT) | tail -c+4)::respawn:/sbin/getty -L $(SKELETON_TARGET_GENERIC_GETTY_OPTIONS) $(SKELETON_TARGET_GENERIC_GETTY_PORT) $(SKELETON_TARGET_GENERIC_GETTY_BAUDRATE) $(SKELETON_TARGET_GENERIC_GETTY_TERM) #~' \
		$(TARGET_DIR)/etc/inittab
endef
else ifeq ($(BR2_INIT_BUSYBOX),y)
# Add getty to busybox inittab
define SKELETON_SYSTEM_GETTY
	$(SED) '/# GENERIC_SERIAL$$/s~^.*#~$(SKELETON_TARGET_GENERIC_GETTY_PORT)::respawn:/sbin/getty -L $(SKELETON_TARGET_GENERIC_GETTY_OPTIONS) $(SKELETON_TARGET_GENERIC_GETTY_PORT) $(SKELETON_TARGET_GENERIC_GETTY_BAUDRATE) $(SKELETON_TARGET_GENERIC_GETTY_TERM) #~' \
		$(TARGET_DIR)/etc/inittab
endef
endif
TARGET_FINALIZE_HOOKS += SKELETON_SYSTEM_GETTY
endif

ifeq ($(BR2_INIT_BUSYBOX)$(BR2_INIT_SYSV),y)
ifeq ($(BR2_TARGET_GENERIC_REMOUNT_ROOTFS_RW),y)
# Find commented line, if any, and remove leading '#'s
define SKELETON_SYSTEM_REMOUNT_RW
	$(SED) '/^#.*-o remount,rw \/$$/s~^#\+~~' $(TARGET_DIR)/etc/inittab
endef
else
# Find uncommented line, if any, and add a leading '#'
define SKELETON_SYSTEM_REMOUNT_RW
	$(SED) '/^[^#].*-o remount,rw \/$$/s~^~#~' $(TARGET_DIR)/etc/inittab
endef
endif
TARGET_FINALIZE_HOOKS += SKELETON_SYSTEM_REMOUNT_RW
endif # BR2_INIT_BUSYBOX || BR2_INIT_SYSV

endif # BR2_ROOTFS_SKELETON_DEFAULT

$(eval $(generic-package))
