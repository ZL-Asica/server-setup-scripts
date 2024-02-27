# 环境配置脚本 - Linux/macOS

## 需求

仅为Debian/Ubuntu/macOS设计。CentOS/RHEL/Fedora请不要使用，暂不支持。

## 使用

注意，为了防止GitHub在你的服务器上无法访问，我这里使用了jsdelivr的CDN链接。如果我刚修改完代码，可能CDN缓存还没有刷新，请使用英文版README里面的命令作为替代。

请确保你的服务器可以正常访问到github，因为脚本中有多处需要访问github的内容。

使用 **curl**

```bash
sudo bash -c "$(curl -fsSL https://cdn.jsdelivr.net/gh/ZL-Asica/server-setup-scripts@main/setup.sh)"
```

使用 **wget**

```bash
sudo bash -c "$(wget -O- https://cdn.jsdelivr.net/gh/ZL-Asica/server-setup-scripts@main/setup.sh)"
```

## macOS（请不要使用root/sudo）

### oh-my-zsh

使用 **curl**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ZL-Asica/server-setup-scripts/main/mac_oh-my-zsh.sh)"
```

### Expo [expo.dev](https://expo.dev/)

Use **curl**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ZL-Asica/server-setup-scripts/main/mac_expo.sh)"
```

### React Native

使用 **curl**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ZL-Asica/server-setup-scripts/main/mac_react-native.sh)"
```

### Flutter

使用 **curl**

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ZL-Asica/server-setup-scripts/main/mac_flutter.sh)"
```
