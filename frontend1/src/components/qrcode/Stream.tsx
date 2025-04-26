import React, { useEffect, useRef, useState } from 'react';
import QrScanner from 'qr-scanner';

interface StreamProps {
  onScanned: (result: string) => void;
}

const Stream: React.FC<StreamProps> = ({ onScanned }) => {
  const [qrCode, setQrCode] = useState<string | null>(null);
  const videoElement = useRef<HTMLVideoElement | null>(null);
  let qrScanner: QrScanner | null = null;

  useEffect(() => {
    if (videoElement.current) {
      qrScanner = new QrScanner(videoElement.current, (result) => {
        setQrCode(result);
        onScanned(result);
      });
      qrScanner.start();
    }

    return () => {
      if (qrScanner) {
        qrScanner.stop();
      }
    };
  }, [onScanned]);

  return (
    <div>
      <video
        className="max-sm:w-72 max-sm:h-72 mx-auto"
        ref={videoElement}
        width="100%"
        height="100%"
      ></video>
      {qrCode && (
        <div className="qr-result">
          <p>Scanned QR Code: {qrCode}</p>
        </div>
      )}
    </div>
  );
};

export default Stream;