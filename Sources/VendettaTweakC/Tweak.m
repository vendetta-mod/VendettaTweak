#import <Orion/Orion.h>

const char * const _Nonnull get_install_prefix(void) {
    return THEOS_PACKAGE_INSTALL_PREFIX;
}

__attribute__((constructor)) static void init() {
    // Initialize Orion - do not remove this line.
    orion_init();
    // Custom initialization code goes here.
}
