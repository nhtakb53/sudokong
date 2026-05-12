import { useEffect, useRef, type ReactNode } from 'react';
import { Animated, Easing, type StyleProp, type ViewStyle } from 'react-native';

type Props = {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
  duration?: number;
  fromScale?: number;
  bounce?: boolean;
  pulse?: boolean;
  delay?: number;
  pointerEvents?: 'auto' | 'none' | 'box-none' | 'box-only';
};

export function AnimatedAppear({
  children,
  style,
  duration = 320,
  fromScale = 0.85,
  bounce = false,
  pulse = false,
  delay = 0,
  pointerEvents,
}: Props) {
  const opacity = useRef(new Animated.Value(0)).current;
  const scale = useRef(new Animated.Value(fromScale)).current;

  useEffect(() => {
    const easing = bounce
      ? Easing.out(Easing.back(1.8))
      : Easing.out(Easing.cubic);

    Animated.timing(opacity, {
      toValue: 1,
      duration,
      delay,
      useNativeDriver: true,
    }).start();

    if (pulse) {
      Animated.sequence([
        Animated.timing(scale, {
          toValue: 1.18,
          duration: duration * 0.55,
          delay,
          easing: Easing.out(Easing.cubic),
          useNativeDriver: true,
        }),
        Animated.timing(scale, {
          toValue: 1,
          duration: duration * 0.6,
          easing: Easing.inOut(Easing.cubic),
          useNativeDriver: true,
        }),
      ]).start();
    } else {
      Animated.timing(scale, {
        toValue: 1,
        duration: duration + 80,
        delay,
        easing,
        useNativeDriver: true,
      }).start();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <Animated.View
      pointerEvents={pointerEvents}
      style={[style, { opacity, transform: [{ scale }] }]}
    >
      {children}
    </Animated.View>
  );
}
