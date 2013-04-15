A=r728;
B=zeros(86400,2);
B(1,:)=A(1,:);
k=2;
for i=2:size(A)
    for j=k:86400
        if A(i,1)~=A(1,1)+j-1
            B(j,:)=[A(1,1)+j-1,B(j-1,2)];
        else
            B(j,:)=A(i,:);
            k=j+1;
            break
        end
    end
end
for m=k:86400
    B(m,:)=[A(1,1)+m-1,B(m-1,2)];
end
%for n=1:24
    %avr=mean(B(1+3600*(n-1):3600*n,2));
    %for l=1+3600*(n-1):3600*n
        %if B(l,2)==0
           % B(l,2)=avr;
        %end
   % end
%end