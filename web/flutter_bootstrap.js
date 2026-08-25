{{flutter_js}}
{{flutter_build_config}}

const swipeatRelease = '20260825-2';

for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) {
    build.mainJsPath = `${build.mainJsPath}?release=${swipeatRelease}`;
  }
}

async function removeStaleServiceWorkers() {
  if (!('serviceWorker' in navigator)) {
    return;
  }

  try {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(
      registrations.map((registration) => registration.unregister()),
    );
  } catch (error) {
    console.warn('Failed to remove a stale service worker.', error);
  }
}

removeStaleServiceWorkers().finally(() => {
  _flutter.loader.load();
});
